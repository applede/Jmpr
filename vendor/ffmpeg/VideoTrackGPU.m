//
//  VideoBufVDA.m
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "VideoTrackGPU.h"
#import "Decoder.h"
#import "VideoFrameGPU.h"
#import "FlexibleQueue.h"
#import "Packet.h"

#define Q_SIZE  8

NSString* const kDisplayTimeKey = @"display_time";

static void OnFrameReadyCallback(void *callback_data,
                                 CFDictionaryRef frame_info,
                                 OSStatus status,
                                 uint32_t flags,
                                 CVImageBufferRef image_buffer) {
  @autoreleasepool {
    assert(status == 0);
    assert(image_buffer);
    assert(CVPixelBufferGetPixelFormatType(image_buffer) == '2vuy');

    NSDictionary* info = (__bridge NSDictionary*)frame_info;
    VideoTrackGPU* videoTrack = (__bridge VideoTrackGPU*)callback_data;
    [videoTrack onFrameReady:image_buffer time:[info[kDisplayTimeKey] doubleValue]];
  }
}

@implementation VideoTrackGPU

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super initDecoder:decoder stream:stream];
  if (self) {
    _frameQue = [[FlexibleQueue alloc] initSize:Q_SIZE];
    int sourceFormat = 'avc1';
    AVCodecContext* context = stream->codec;
    NSDictionary* config = @{(id)kVDADecoderConfiguration_Width:@(_width),
                             (id)kVDADecoderConfiguration_Height:@(_height),
                             (id)kVDADecoderConfiguration_SourceFormat:@(sourceFormat),
                             (id)kVDADecoderConfiguration_avcCData:[NSData dataWithBytes:context->extradata
                                                                                  length:context->extradata_size]};
    assert(context->extradata);
    NSDictionary* formatInfo = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_422YpCbCr8),
                                 (id)kCVPixelBufferIOSurfacePropertiesKey: @{}};

    OSStatus status = VDADecoderCreate((__bridge CFDictionaryRef)config,
                                       (__bridge CFDictionaryRef)formatInfo, // optional
                                       (VDADecoderOutputCallback*)OnFrameReadyCallback,
                                       (__bridge void*)self,
                                       &_vdaDecoder);
    if (status == kVDADecoderHardwareNotSupportedErr)
      fprintf(stderr, "hadware does not support GPU decoding\n");
    assert(status == kVDADecoderNoErr);
  }
  return self;
}

- (void)dealloc
{
  VDADecoderDestroy(_vdaDecoder);
}

- (void)onFrameReady:(CVPixelBufferRef)image time:(double)time
{
  VideoFrameGPU* v = [[VideoFrameGPU alloc] initImage:image time:time];
  [_frameQue add:v];
}

- (void)prepare:(CGLContextObj)cgl
{
  CGLSetCurrentContext(cgl);
  _cglCtx = cgl;
  glEnable(GL_TEXTURE_RECTANGLE_ARB);
  glGenTextures(1, &_texture);

  [self compileVertex:
   "#version 120\n"
   "attribute vec2 Position;\n"
   "attribute vec2 TexCoordIn;\n"
   "varying vec2 TexCoordOut;\n"
   "uniform mat4 Ortho;\n"
   "void main()\n"
   "{\n"
   "  gl_Position = Ortho * vec4(Position, 0, 1);"
   "  TexCoordOut = TexCoordIn;"
   "}"
             fragment:
   "#version 120\n"
   "uniform sampler2DRect sampler0;"
   "varying vec2 TexCoordOut;"
   "void main(void)"
   "{"
   "  gl_FragColor = texture2DRect(sampler0, TexCoordOut);"
   "}"];
  glUseProgram(_program);
  GLint sampler0 = glGetUniformLocation(_program, "sampler0");
  assert(sampler0 >= 0);
  glUniform1i(sampler0, 0);

  GLint position = glGetAttribLocation(_program, "Position");
  assert(position >= 0);
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(position);

  GLint texcoord = glGetAttribLocation(_program, "TexCoordIn");
  assert(texcoord >= 0);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, 0, (char*)0 + 8 * sizeof(GLfloat));
  glEnableVertexAttribArray(texcoord);
}

- (double)frontTime
{
  if ([_frameQue isEmpty]) {
    return DBL_MAX;
  }
  return [[_frameQue front] time];
}

- (void)decode
{
  AVRational tb = _stream->time_base;

  Packet* pkt = [_decoder.videoQue get];
  if ([pkt isFlush]) {
    [_frameQue flush];
    return;
  }
  assert(pkt.data);

  NSData* data = [NSData dataWithBytes:pkt.data length:pkt.size];
  double pts = pkt.pts * av_q2d(tb);
  NSDictionary* frame_info = @{kDisplayTimeKey:@(pts)};
  OSStatus r = VDADecoderDecode(_vdaDecoder, 0, (__bridge CFDataRef)data,
                                (__bridge CFDictionaryRef)frame_info);
  assert(r == 0);
  av_free_packet(pkt.packet);
}

- (BOOL)canContinue
{
  return !_quit && ![_decoder.videoQue isEmpty] && ![_frameQue isFull];
}

- (void)draw
{
  VideoFrameGPU* v = [_frameQue get];
  IOSurfaceRef surface = [v surface];
  GLsizei	width	= (GLsizei)IOSurfaceGetWidth(surface);
  GLsizei	height = (GLsizei)IOSurfaceGetHeight(surface);

  glEnable(GL_TEXTURE_RECTANGLE_ARB);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
  CGLTexImageIOSurface2D(_cglCtx, GL_TEXTURE_RECTANGLE_ARB, GL_RGB8,
                         width, height,
                         GL_YCBCR_422_APPLE, GL_UNSIGNED_SHORT_8_8_APPLE, surface, 0);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
  glDisable(GL_TEXTURE_RECTANGLE_ARB);

  glFlush();

  glUseProgram(_program);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
  glDrawArrays(GL_QUADS, 0, 4);

  [self checkQue];
}

- (void)flush
{
  [_frameQue flush];
  [self checkQue];
}

@end
