//
//  SubtitleBuf.h
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import <Quartz/Quartz.h>
#import "CircularQueue.h"

@class Decoder;

@interface SubtitleTrack : NSObject
{
  Decoder* _decoder;
  AVStream* _stream;
}

- (id)initDecoder:(Decoder*)decoder stream:(AVStream*)stream;
- (void)start;
- (void)checkQue;
- (int)encoding;

/// @return nil means no change needed
- (NSString*)stringForTime:(double)t;

@end
