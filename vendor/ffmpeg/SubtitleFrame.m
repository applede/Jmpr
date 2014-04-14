//
//  SubtitleFrame.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleFrame.h"

@implementation SubtitleFrame

- (void)dealloc
{
  avsubtitle_free(&_sub);
}

- (AVSubtitle*)sub
{
  return &_sub;
}

- (int64_t)pts
{
  return _sub.pts;
}

- (double)endTime
{
  return _time + _sub.end_display_time / 1000.0;
}

- (AVSubtitleRect**)rects
{
  return _sub.rects;
}

- (const char*)ass
{
  return _sub.rects[0]->ass;
}

@end
