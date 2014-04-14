//
//  Packet.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@interface Packet : NSObject
{
  AVPacket _packet;
}

+ (Packet*)flushPacket;

- initPacket:(AVPacket*)packet;
- (AVPacket*)packet;
- (int)streamIndex;
- (uint8_t*)data;
- (int)size;
- (int64_t)pts;
- (BOOL)isFlush;

@end
