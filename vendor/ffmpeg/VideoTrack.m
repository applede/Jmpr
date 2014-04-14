//
//  VideoQueue.m
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libswscale/swscale.h>
#import "VideoTrack.h"
#import "Decoder.h"

@implementation VideoTrack

- initDecoder:(Decoder*)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _decoder = decoder;
    _stream = stream;
    _sema = dispatch_semaphore_create(0);
    AVCodecContext* context = stream->codec;
    _width = context->width;
    _height = context->height;
  }
  return self;
}

- (int)width
{
  return _width;
}

- (int)height
{
  return _height;
}

- (float)textureWidth
{
  return _width;
}

- (float)textureHeight
{
  return _height;
}

GLuint compileShader(GLenum type, const GLchar* src)
{
  GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &src, NULL);
  glCompileShader(shader);
  GLint compile_ok = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compile_ok);
  if (!compile_ok) {
    NSLog(@"compile failed");
  }
  char log[2048];
  int logLen = 0;
  glGetShaderInfoLog(shader, sizeof(log), &logLen, log);
  if (logLen > 0) {
    NSLog(@"%s", log);
  }
  return shader;
}

- (void)compileVertex:(const char*)vertexSrc fragment:(const char*)fragmentSrc
{
  GLuint vertexShader = compileShader(GL_VERTEX_SHADER, vertexSrc);
  GLuint fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);

  _program = glCreateProgram();
  glAttachShader(_program, vertexShader);
  glAttachShader(_program, fragmentShader);
  glLinkProgram(_program);
  int logLen;
  glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLen);
  if (logLen > 0) {
    char log[2048];
    glGetProgramInfoLog(_program, sizeof(log), &logLen, log);
    NSLog(@"%s", log);
  }
}

- (void)prepare:(CGLContextObj)cgl
{
}

- (double)frontTime
{
  return DBL_MAX;
}

- (void)decode
{
}

- (void)draw
{
}

- (void)start
{
  dispatch_queue_t q = dispatch_queue_create("jap.video.decode", DISPATCH_QUEUE_SERIAL);
  dispatch_async(q, ^{
    while (!_quit) {
      @autoreleasepool {
        while ([self canContinue]) {
          [self decode];
        }
        [_decoder checkQue];
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
      }
    }
  });
}

- (void)checkQue
{
  if ([self canContinue]) {
    dispatch_semaphore_signal(_sema);
  }
}

- (BOOL)canContinue
{
  return NO;
}

void makeOrtho(GLfloat width, GLfloat height, GLfloat* mat)
{
  GLfloat left = 0;
  GLfloat right = width;
  GLfloat bottom = 0;
  GLfloat top = height;
  GLfloat near = -1;
  GLfloat far = 1;

  mat[0] = 2.0 / (right - left);
  mat[1] = 0;
  mat[2] = 0;
  mat[3] = 0;

  mat[4] = 0;
  mat[5] = 2.0 / (top - bottom);
  mat[6] = 0;
  mat[7] = 0;

  mat[8] = 0;
  mat[9] = 0;
  mat[10] = -2.0 / (far - near);
  mat[11] = 0;

  mat[12] = -(right + left) / (right - left);
  mat[13] = -(top + bottom) / (top - bottom);
  mat[14] = -(far + near) / (far - near);
  mat[15] = 1.0;
}

- (void)viewWidth:(GLfloat)width height:(GLfloat)height
{
  glUseProgram(_program);
  GLint ortho = glGetUniformLocation(_program, "Ortho");
  assert(ortho >= 0);
  GLfloat orthoMat[16];
  makeOrtho(width, height, orthoMat);
  glUniformMatrix4fv(ortho, 1, NO, orthoMat);
}

- (void)flush
{
}

@end