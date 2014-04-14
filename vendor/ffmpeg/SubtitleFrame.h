//
//  SubtitleFrame.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@interface SubtitleFrame : NSObject
{
  AVSubtitle _sub;
}

@property double time;

- (AVSubtitle*)sub;
- (double)endTime;
- (int64_t)pts;
- (AVSubtitleRect**)rects;
- (const char*)ass;

@end
