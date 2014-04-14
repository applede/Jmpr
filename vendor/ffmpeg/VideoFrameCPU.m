//
//  VideoFrameCPU.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "VideoFrameCPU.h"

@implementation VideoFrameCPU

- (id)initData:(uint8_t*)data width:(int)width height:(int)height
{
  self = [super init];
  if (self) {
    _frame = av_frame_alloc();
    avpicture_fill((AVPicture*)_frame, data, AV_PIX_FMT_YUV420P, width, height);
  }
  return self;
}

- (void)dealloc
{
  av_frame_free(&_frame);
}

- (uint8_t *)dataY
{
  return _frame->data[0];
}

- (uint8_t *)dataU
{
  return _frame->data[1];
}

- (uint8_t *)dataV
{
  return _frame->data[2];
}

- (int)strideY
{
  return _frame->linesize[0];
}

- (int)strideU
{
  return _frame->linesize[1];
}

- (int)strideV
{
  return _frame->linesize[2];
}

@end
