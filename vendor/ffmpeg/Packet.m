//
//  Packet.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "Packet.h"

static Packet* _flushPacket;

@implementation Packet

+ (Packet*)flushPacket
{
  if (!_flushPacket) {
    AVPacket empty = { 0 };
    _flushPacket = [[Packet alloc] initPacket:&empty];
  }
  return _flushPacket;
}

- (id)initPacket:(AVPacket *)packet
{
  self = [super init];
  if (self) {
    int r = av_dup_packet(packet);
    assert(r >= 0);
    _packet = *packet;
  }
  return self;
}

- (void)dealloc
{
  av_free_packet(&_packet);
}

- (AVPacket *)packet
{
  return &_packet;
}

- (int)streamIndex
{
  return _packet.stream_index;
}

- (uint8_t *)data
{
  return _packet.data;
}

- (int)size
{
  return _packet.size;
}

- (int64_t)pts
{
  return _packet.pts;
}

- (BOOL)isFlush
{
  return self == _flushPacket;
}

@end
