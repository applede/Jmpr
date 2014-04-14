//
//  MyOpenGLLayer.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <OpenGL/gl.h>
#import "MyOpenGLLayer.h"

@implementation MyOpenGLLayer

- (NSOpenGLContext *)openGLContextForPixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
  NSOpenGLContext* ctx = [super openGLContextForPixelFormat:pixelFormat];
  if (!_decoder) {
    _decoder = [[Decoder alloc] init];
  }
  [self initGL:ctx];
  self.needsDisplayOnBoundsChange = YES;
  self.backgroundColor = [[NSColor blackColor] CGColor];
  self.asynchronous = NO;
  return ctx;
}

- (void)initGL:(NSOpenGLContext*)ctx
{
  [ctx makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[ctx setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_TEXTURE_2D);
	
  glGenBuffers(1, &buffer_);
  glBindBuffer(GL_ARRAY_BUFFER, buffer_);
  glBufferData(GL_ARRAY_BUFFER, 16 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);
}

- (BOOL)canDrawInOpenGLContext:(NSOpenGLContext *)context
                   pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
                  forLayerTime:(CFTimeInterval)lt displayTime:(const CVTimeStamp *)ts
{
  double t = [_decoder masterClock];
  return _decoder.videoTrack && [_decoder.videoTrack frontTime] <= t;
}

- (void)drawInOpenGLContext:(NSOpenGLContext *)context
                pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
               forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts;
{
  @autoreleasepool {
    [self draw];
    [_subtitleDelegate displaySubtitle];
  }
}

- (void)draw
{
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  [_decoder.videoTrack draw];
}

- (BOOL)frameChanged
{
  NSOpenGLContext* context = self.openGLContext;
  if (context && _decoder.videoTrack) {
    [self.openGLContext makeCurrentContext];
    [self reshape];
    return YES;
  }
  return NO;
}

- (void) reshape
{
  NSRect rect = self.bounds;
  CGFloat s = self.contentsScale;
  GLfloat vw = rect.size.width * s;
  GLfloat vh = rect.size.height * s;
	
  [_decoder.videoTrack viewWidth:vw height:vh];
  [self calcRect];
  
  GLfloat x0 = _movieRect.origin.x;
  GLfloat y0 = _movieRect.origin.y;
  GLfloat x1 = _movieRect.origin.x + _movieRect.size.width;
  GLfloat y1 = _movieRect.origin.y + _movieRect.size.height;
  GLfloat w = [_decoder.videoTrack textureWidth];
  GLfloat h = [_decoder.videoTrack textureHeight];
  GLfloat vertices[16] = {
    x0, y0,   x0, y1,   x1, y1,   x1, y0,
    0, h,     0, 0,     w, 0,     w, h
  };
  glBindBuffer(GL_ARRAY_BUFFER, buffer_);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);
}

- (void)calcRect
{
  CGRect bounds = self.bounds;
  CGFloat s = self.contentsScale;
  bounds.size.width *= s;
  bounds.size.height *= s;
  
  int srcW = _decoder.videoTrack.width;
  int srcH = _decoder.videoTrack.height;
  GLfloat viewW = bounds.size.width;
  GLfloat viewH = bounds.size.height;

  GLfloat dstW = viewH * srcW / srcH;
  GLfloat dstH;

  if (dstW <= viewW) {
    dstH = viewH;
  } else {
    dstH = viewW * srcH / srcW;
    dstW = viewW;
  }
  
  _movieRect.origin.x = (viewW - dstW) / 2;
  _movieRect.origin.y = (viewH - dstH) / 2;
  _movieRect.size.width = dstW;
  _movieRect.size.height = dstH;
}

- (void)open:(NSString *)path
{
  [_decoder open:path];
  [_decoder.videoTrack prepare:self.openGLContext.CGLContextObj];
  self.asynchronous = YES;
}

@end
