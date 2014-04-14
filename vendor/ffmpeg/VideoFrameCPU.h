//
//  VideoFrameCPU.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@interface VideoFrameCPU : NSObject

@property double time;
@property (readonly) AVFrame* frame;
@property GLuint textureY;
@property GLuint textureU;
@property GLuint textureV;

- (id)initData:(uint8_t*)data width:(int)width height:(int)height;
- (uint8_t*)dataY;
- (uint8_t*)dataU;
- (uint8_t*)dataV;
- (int)strideY;
- (int)strideU;
- (int)strideV;

@end
