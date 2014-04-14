//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@class Decoder;

#define TEXTURE_COUNT		5

@interface VideoTrack : NSObject
{
  BOOL _quit;
  Decoder* _decoder;
  AVStream* _stream;
  dispatch_semaphore_t _sema;

  GLuint _program;
  int _width;
  int _height;
}

- initDecoder:(Decoder*)decoder stream:(AVStream *)stream;

- (int)width;
- (int)height;
- (float)textureWidth;
- (float)textureHeight;

- (void)compileVertex:(const char*)vertexSrc fragment:(const char*)fragmentSrc;
- (void)prepare:(CGLContextObj)cgl;
- (void)viewWidth:(GLfloat)width height:(GLfloat)height;

- (double)frontTime;
- (void)decode;
- (void)draw;

- (void)start;
- (void)checkQue;
- (BOOL)canContinue;
- (void)flush;

@end
