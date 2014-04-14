//
//  VideoFrame.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "VideoFrameGPU.h"

@implementation VideoFrameGPU

- (id)initImage:(CVPixelBufferRef)i time:(double)t
{
  self = [super init];
  if (self) {
    time = t;
    image = CVBufferRetain(i);
    surface = CVPixelBufferGetIOSurface(image);
    CFRetain(surface);
  }
  return self;
}

- (void)dealloc
{
  CFRelease(image);
  CFRelease(surface);
}

- (double)time
{
  return time;
}

- (IOSurfaceRef)surface
{
  return surface;
}

@end
