//
//  VideoBufCPU.h
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoTrack.h"
#import "CircularQueue.h"

@interface VideoTrackCPU : VideoTrack
{
  CircularQueue* _frameQue;
  
  int _frameSize;
  int _size;
  GLubyte* _data;

  struct SwsContext *_imgConvertCtx;
}

- initDecoder:(Decoder*)decoder stream:(AVStream*)stream;

@end
