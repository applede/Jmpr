//
//  AudioQueue.h
//  Jap
//
//  Created by Jake Song on 3/20/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

@class Decoder;

typedef struct {
  int freq;
  int channels;
  int64_t channel_layout;
  enum AVSampleFormat fmt;
  int frame_size;
  int bytes_per_sec;
} AudioParams;

@interface AudioTrack : NSObject
{
  Decoder* _decoder;
  AVStream* _stream;
  
  AudioComponentInstance _audioC;
  
  AVPacket _audio_pkt_temp;
  AVPacket _audio_pkt;
  int _audio_buf_frames_pending;
  AVFrame *_frame;
  int _paused;
  int _audio_finished;
  int _audio_pkt_temp_serial;
  int64_t _audio_frame_next_pts;
  AudioParams _audio_src;
  AudioParams _audio_tgt;
  struct SwrContext *_swr_ctx;
  uint8_t _silence[1024];
  uint8_t *_audio_buf;
  uint8_t *_audio_buf1;
  unsigned int _audio_buf1_size;
  double _audio_clock;
  int _audio_clock_serial;
  int _audio_buf_index;
  int _audio_buf_size;

  BOOL _playing;
}

- (id)initDecoder:(Decoder*)decoder stream:(AVStream *)stream;

- (void)stop;
- (BOOL)isPlaying;
- (void)play;
- (void)pause;

- (BOOL)prepare;
- (void)close;

- (double)clock;

@end
