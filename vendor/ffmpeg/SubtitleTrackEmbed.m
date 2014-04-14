//
//  SubtitleTrackIn.m
//  Jap
//
//  Created by Jake Song on 3/31/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleTrackEmbed.h"
#import "Decoder.h"
#import "SubtitleFrame.h"
#import "Packet.h"

#define QSIZE 32

@implementation SubtitleTrackEmbed

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super initDecoder:decoder stream:stream];
  if (self) {
    _sema = dispatch_semaphore_create(0);
    _frameQue = [[CircularQueue alloc] initSize:QSIZE];
    for (int i = 0; i < QSIZE; i++) {
      _frameQue[i] = [[SubtitleFrame alloc] init];
    }
  }
  return self;
}

- (void)start
{
  dispatch_queue_t q = dispatch_queue_create("jap.subtitle.embedded", DISPATCH_QUEUE_SERIAL);
  dispatch_async(q, ^{
    int got_subtitle;
    double pts;
    
    while (!_quit) {
      @autoreleasepool {
        while ([self canContinue]) {
          Packet* packet = [_decoder.subtitleQue get];
          if ([packet isFlush]) {
            avcodec_flush_buffers(_stream->codec);
            [_frameQue flush];
            continue;
          }
          pts = 0;
          if (packet.pts != AV_NOPTS_VALUE)
            pts = av_q2d(_stream->time_base) * packet.pts;
          SubtitleFrame* s = [_frameQue back];
          avcodec_decode_subtitle2(_stream->codec, s.sub, &got_subtitle, packet.packet);
          if (got_subtitle) {
            if (s.pts != AV_NOPTS_VALUE)
                pts = s.pts / (double)AV_TIME_BASE;
            if (s.rects) {
              [self put:s time:pts];
            } else {
              assert(s.rects);
            }
          }
        }
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
      }
    }
  });
}

- (BOOL)canContinue
{
  return !_quit && ![_decoder.subtitleQue isEmpty] && ![_frameQue isFull];
}

- (void)checkQue
{
  if ([self canContinue]) {
    dispatch_semaphore_signal(_sema);
  }
}

- (void)put:(SubtitleFrame*)s time:(double)time
{
  s.time = time;
  [_frameQue advance];
}

- (SubtitleFrame*)get:(double)time
{
  SubtitleFrame* s = [_frameQue front];
  if (s.time <= time) {
    return s;
  }
  return nil;
}

static const char* findSub(const char* str)
{
  int count = 0;
  while (*str && count < 4) {
    if (*str == ',') {
      count++;
    }
    str++;
  }
  return str;
}

// returns number of lines
static int convert(const char* src, char* dst)
{
  int n = 1;
  while (*src) {
    if (*src == '\\' && src[1] == 'N') {
      *dst++ = '\n';
      src += 2;
      n++;
    } else {
      *dst++ = *src++;
    }
  }
  *dst = 0;
  return n;
}

- (NSString*)stringForTime:(double)t
{
  NSString* ret = nil;
  if ([_frameQue isEmpty]) {
    return @"";
  }
  SubtitleFrame* s = [self get:t];
  if (s) {
    if (s.endTime <= t) {
      ret = @"";
      [_frameQue get];
    } else {
      char buf[2048];
      convert(findSub(s.ass), buf);
      ret = [NSString stringWithUTF8String:buf];
    }
  }
  return ret;
}

@end
