//
//  VideoBufVDA.h
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoDecodeAcceleration/VDADecoder.h>
#import "VideoTrack.h"
#import "FlexibleQueue.h"

@interface VideoTrackGPU : VideoTrack
{
  VDADecoder _vdaDecoder;
  CGLContextObj _cglCtx;
  FlexibleQueue* _frameQue;
  GLuint _texture;
}

- initDecoder:(Decoder*)decoder stream:(AVStream *)stream;
- (void)onFrameReady:(CVImageBufferRef)image time:(double)time;

@end
