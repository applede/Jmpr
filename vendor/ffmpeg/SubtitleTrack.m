//
//  SubtitleBuf.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleTrack.h"
#import "SubtitleFrame.h"

@implementation SubtitleTrack

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _decoder = decoder;
    _stream = stream;
  }
  return self;
}

- (void)start
{
}

- (void)checkQue
{
}

- (NSString*)stringForTime:(double)t
{
  return nil;
}

- (int)encoding
{
  return kCFStringEncodingUTF8;
}

@end
