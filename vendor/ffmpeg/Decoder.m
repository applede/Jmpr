//
//  Decoder.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libavcodec/avcodec.h>
#import <libavutil/opt.h>
#import "Decoder.h"
#import "Packet.h"

#define PACKET_Q_SIZE 300

@implementation Decoder

- (id)init
{
  self = [super init];
  if (self) {
    _quit = NO;
    _videoQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _audioQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _subtitleQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _readQ = dispatch_queue_create("jap.read", DISPATCH_QUEUE_SERIAL);
    _readSema = dispatch_semaphore_create(0);
    av_register_all();
  }
  return self;
}

- (void)open:(NSString *)p
{
  _path = p;
  _quit = NO;
  [self readThread];
  [_videoTrack start];
  [_audioTrack play];
  [_subtitleTrack start];
}

- (BOOL)isPlaying
{
  return [_audioTrack isPlaying];
}

- (void)play
{
  [_audioTrack play];
}

- (void)pause
{
  [_audioTrack pause];
}

- (void)stop
{
  _quit = YES;
  [_audioTrack stop];
}

- (void)seek:(double)inc
{
  double pos = [self masterClock];
  pos += inc;

  double startTime = (double)_formatContext->start_time / AV_TIME_BASE;
  if (_formatContext->start_time != AV_NOPTS_VALUE && pos < startTime) {
    pos = startTime;
  }

  if (!_seekReq) {
    _seekPos = (int64_t)(pos * AV_TIME_BASE);
    _seekInc = (int64_t)(inc * AV_TIME_BASE);
    _seekReq = YES;
    dispatch_semaphore_signal(_readSema);
  }
}

- (BOOL)supportsSeek
{
  // negate (doesNotSupportSeek)
  return !((_formatContext->iformat->flags & (AVFMT_NOBINSEARCH | AVFMT_NOGENSEARCH | AVFMT_NO_BYTE_SEEK)) && !_formatContext->iformat->read_seek);
}

- (double)masterClock
{
  return [_audioTrack clock];
}

- (void)readThread
{
  if ([self internalOpen:_path]) {
    dispatch_async(_readQ, ^{
      while (!_quit) {
        @autoreleasepool {
          [self read];
          dispatch_semaphore_wait(_readSema, DISPATCH_TIME_FOREVER);
        }
      }
    });
  } else {
    [self close];
  }
}

- (AVStream*)openStream:(int)i
{
  AVCodecContext *avctx = _formatContext->streams[i]->codec;
  AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
  
  avctx->codec_id = codec->id;
  avctx->workaround_bugs = 1;
  av_codec_set_lowres(avctx, 0);
  avctx->error_concealment = 3;
  AVDictionary *opts = NULL;
  av_dict_set(&opts, "threads", "auto", 0);
  if (avctx->codec_type == AVMEDIA_TYPE_VIDEO || avctx->codec_type == AVMEDIA_TYPE_AUDIO)
    av_dict_set(&opts, "refcounted_frames", "1", 0);
  if (avcodec_open2(avctx, codec, &opts) < 0) {
    NSLog(@"avcodec_open2");
    return nil;
  }
  _formatContext->streams[i]->discard = AVDISCARD_DEFAULT;
  return _formatContext->streams[i];
}

/// @return nil if smi file does not exist

NSString* smiPath(NSString* path)
{
  NSString* filename = [path stringByDeletingPathExtension];
  NSString* smiPath = [filename stringByAppendingPathExtension:@"smi"];
  BOOL dir;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:smiPath isDirectory:&dir];
  if (!exists || dir) {
    smiPath = nil;
  }
  return smiPath;
}

- (BOOL)internalOpen:(NSString*)filename
{
  _formatContext = NULL;
  int err = avformat_open_input(&_formatContext, [filename UTF8String], NULL, NULL);
  if (err < 0) {
    NSLog(@"avformat_open_input %d", err);
    return NO;
  }
  err = avformat_find_stream_info(_formatContext, NULL);
  if (err < 0) {
    NSLog(@"avformat_find_stream_info %d", err);
    return NO;
  }
  _videoStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
  AVCodecContext* context = _formatContext->streams[_videoStream]->codec;
  if (context->codec_id == AV_CODEC_ID_H264) {
    _videoTrack = [[VideoTrackGPU alloc] initDecoder:self stream:_formatContext->streams[_videoStream]];
  } else {
    _videoTrack = [[VideoTrackCPU alloc] initDecoder:self stream:[self openStream:_videoStream]];
  }
  
  _audioStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_AUDIO, -1, _videoStream, NULL, 0);
  _audioTrack = [[AudioTrack alloc] initDecoder:self stream:[self openStream:_audioStream]];
  [_audioTrack prepare];

  NSString* smiP = smiPath(_path);
  _subtitleTrack = [[SubtitleTrackSMI alloc] initDecoder:self
                                                  stream:_formatContext->streams[_videoStream] path:smiP];
  if (_subtitleTrack) {
    _subtitleStream = -1;
  } else {
    _subtitleStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_SUBTITLE, -1,
                                          (_audioStream >= 0 ? _audioStream : _videoStream),
                                          NULL, 0);
    _subtitleTrack = [[SubtitleTrackEmbed alloc] initDecoder:self stream:[self openStream:_subtitleStream]];
  }
 
  return YES;
}

- (void)read
{
  if (_seekReq) {
    int64_t seekTarget = _seekPos;
    int64_t seekMin = _seekInc > 0 ? seekTarget - _seekInc + 2 : INT64_MIN;
    int64_t seekMax = _seekInc < 0 ? seekTarget - _seekInc - 2 : INT64_MAX;
    int ret = avformat_seek_file(_formatContext, -1, seekMin, seekTarget, seekMax, 0);
    if (ret < 0) {
      NSLog(@"avformat_seek_file %d", ret);
    } else {
      [_videoQue flush];
      [_videoQue put:[Packet flushPacket]];
      [_audioQue flush];
      [_audioQue put:[Packet flushPacket]];
      [_subtitleQue flush];
      [_subtitleQue put:[Packet flushPacket]];
      [_videoTrack flush];
    }
    _seekReq = NO;
  }
  while ([self canContinue]) {
    Packet* packet = [[Packet alloc] init];
    int ret = av_read_frame(_formatContext, packet.packet);
    if (ret < 0) {
      NSLog(@"av_read_frame %d", ret);
    } else {
      if (packet.streamIndex == _videoStream) {
        [_videoQue put:packet];
        [_videoTrack checkQue];
      } else if (packet.streamIndex == _audioStream)
        [_audioQue put:packet];
      else if (packet.streamIndex == _subtitleStream) {
        [_subtitleQue put:packet];
        [_subtitleTrack checkQue];
      }
    }
  }
}

- (void)close
{
  if (_formatContext) {
    avformat_close_input(&_formatContext);
  }
  [_audioTrack close];
}

- (void)checkQue
{
//  if ([self canContinue]) {
//    dispatch_semaphore_signal(_readSema);
//  }

  if ([_videoQue count] < PACKET_Q_SIZE / 2 &&
      [_audioQue count] < PACKET_Q_SIZE / 2 &&
      [_subtitleQue count] < PACKET_Q_SIZE / 2) {
    dispatch_semaphore_signal(_readSema);
  }
}

- (BOOL)canContinue
{
  return ![_videoQue isFull] && ![_audioQue isFull] && ![_subtitleQue isFull];
}

- (NSString *)subtitleString
{
  return [_subtitleTrack stringForTime:[self masterClock]];
}

@end
