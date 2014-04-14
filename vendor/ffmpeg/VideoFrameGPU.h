//
//  VideoFrame.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlexibleQueue.h"

@interface VideoFrameGPU : NSObject<Time>
{
  double time;
  CVPixelBufferRef image;
  IOSurfaceRef surface;
}

- initImage:(CVPixelBufferRef)image time:(double)time;
- (IOSurfaceRef)surface;

@end
