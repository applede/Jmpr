//
//  SubtitleTrackSMI.m
//  Jap
//
//  Created by Jake Song on 3/31/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleTrackSMI.h"
#import "ParserSMI.h"

@implementation SubtitleTrackSMI

- (id)initDecoder:(Decoder *)decoder stream:(AVStream*)stream path:(NSString *)path
{
  self = [super initDecoder:decoder stream:stream];
  if (self) {
    ParserSMI* parser = [[ParserSMI alloc] initPath:path];
    if (parser) {
      _nodes = [parser nodes];
      _current = 0;
      return self;
    }
  }
  return nil;
}

- (NSString*)stringForTime:(double)target
{
  NSString* ret = nil;
  int i = _current;
  int dir = 1;
  if (_lastTime > target) {
    dir = -1;
  }
  _lastTime = target;
  while (i >= 0 && i < [_nodes count]) {
    Node* node = [_nodes objectAtIndex:i];
    double t = av_q2d(_stream->time_base) * [node time];
    if ((dir > 0 && t <= target) || (dir < 0 && t >= target)) {
      ret = [node string];
      i += dir;
    } else {
      break;
    }
  }
  if (i < 0) {
    ret = @"";
    _current = 0;
  } else if (i >= [_nodes count]) {
  } else {
    _current = i;
  }
  return ret;
}

- (int)encoding
{
  return kCFStringEncodingDOSKorean;
}

@end
