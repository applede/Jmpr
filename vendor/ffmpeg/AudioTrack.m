//
//  AudioQueue.m
//  Jap
//
//  Created by Jake Song on 3/20/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <CoreAudio/HostTime.h>
#import <libswresample/swresample.h>
#import "AudioTrack.h"
#import "Decoder.h"
#import "Packet.h"

#define SAMPLE_SIZE sizeof(float)

@implementation AudioTrack

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _decoder = decoder;
    _stream = stream;
  }
  return self;
}

- (void)stop
{
  [self pause];
}

- (void)play
{
  _playing = YES;
  AudioOutputUnitStart(_audioC);
}

- (void)pause
{
  _playing = NO;
  AudioOutputUnitStop(_audioC);
}

- (BOOL)isPlaying
{
  return _playing;
}

static OSStatus audioCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
  [(__bridge AudioTrack*)inRefCon nextAudio:inTimeStamp busNumber:inBusNumber
                      frameNumber:inNumberFrames audioData:ioData];
  return noErr;
}

- (void)close
{
  if (_audioC) {
    if (AudioUnitUninitialize(_audioC) != 0) {
      NSLog(@"AudioUnitUninitialize");
    }
    if (AudioComponentInstanceDispose(_audioC) != 0) {
      NSLog(@"AudioComponentInstanceDispose");
    }
    _audioC = 0;
  }
}

- (BOOL)prepare
{
  _audio_pkt_temp.stream_index = -1;
  
  AudioComponentDescription desc;
  desc.componentType = kAudioUnitType_Output;
  desc.componentSubType = kAudioUnitSubType_DefaultOutput;
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  AudioComponent component = AudioComponentFindNext(0, &desc);
  if (!component) {
    NSLog(@"AudioComponentFindNext");
    return NO;
  }
  int err = AudioComponentInstanceNew(component, &_audioC);
  if (err != noErr) {
    NSLog(@"AudioComponentInstanceNew %d", err);
    return NO;
  }
  AURenderCallbackStruct cb;
  cb.inputProc = audioCallback;
  cb.inputProcRefCon = (__bridge void*)self;
  err = AudioUnitSetProperty(_audioC,
                             kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Input,
                             0, &cb, sizeof(cb));
  if (err != noErr) {
    NSLog(@"AudioUnitSetProperty(callback) failed : %d\n", err);
    return NO;
  }
  AVCodecContext* context = _stream->codec;
  AudioStreamBasicDescription streamFormat;
  streamFormat.mSampleRate = context->sample_rate;
  streamFormat.mFormatID = kAudioFormatLinearPCM;
  streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
  streamFormat.mBytesPerPacket = SAMPLE_SIZE * context->channels;
  streamFormat.mFramesPerPacket = 1;
  streamFormat.mBytesPerFrame = SAMPLE_SIZE * context->channels;
  streamFormat.mChannelsPerFrame = context->channels;
  streamFormat.mBitsPerChannel = SAMPLE_SIZE * 8;
  err = AudioUnitSetProperty(_audioC,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Input,
                             0, &streamFormat, sizeof(streamFormat));
  if (err != noErr) {
    NSLog(@"AudioUnitSetProperty(streamFormat) failed : %d\n", err);
    return NO;
  }
  // Initialize unit
  err = AudioUnitInitialize(_audioC);
  if (err) {
    NSLog(@"AudioUnitInitialize=%d", err);
    return FALSE;
  }
  
  Float64 outSampleRate;
  UInt32 size = sizeof(Float64);
  err = AudioUnitGetProperty(_audioC,
                             kAudioUnitProperty_SampleRate,
                             kAudioUnitScope_Output,
                             0, &outSampleRate, &size);
  if (err) {
    NSLog(@"AudioUnitSetProperty-GF=%4.4s, %d", (char*)&err, err);
    return NO;
  }
  
  int64_t wanted_channel_layout = av_get_default_channel_layout(context->channels);
  
  _audio_tgt.fmt = AV_SAMPLE_FMT_FLT;
  _audio_tgt.freq = outSampleRate;
  _audio_tgt.channel_layout = wanted_channel_layout;
  _audio_tgt.channels = context->channels;
  _audio_tgt.frame_size = av_samples_get_buffer_size(NULL, _audio_tgt.channels, 1, _audio_tgt.fmt, 1);
  _audio_tgt.bytes_per_sec = av_samples_get_buffer_size(NULL, _audio_tgt.channels, _audio_tgt.freq, _audio_tgt.fmt, 1);
  _audio_src = _audio_tgt;
  _audio_buf_index = 0;
  _audio_buf_size = 0;

  return YES;
}

- (void)nextAudio:(const AudioTimeStamp*)timeStamp busNumber:(UInt32)busNumber
      frameNumber:(UInt32)numberFrames audioData:(AudioBufferList*)ioData
{
  @autoreleasepool {
    int audio_size, available;
    int requested = numberFrames * SAMPLE_SIZE * ioData->mBuffers[0].mNumberChannels;
    uint8_t* dst = ioData->mBuffers[0].mData;
    
    while (requested > 0) {
      if (_audio_buf_index >= _audio_buf_size) {
        audio_size = [self decodeAudio:ioData];
        if (audio_size < 0) {
          /* if error, just output silence */
          _audio_buf = _silence;
          _audio_buf_size = sizeof(_silence);
        } else {
          _audio_buf_size = audio_size;
        }
        _audio_buf_index = 0;
      }
      available = _audio_buf_size - _audio_buf_index;
      if (available > requested)
        available = requested;
      memcpy(dst, _audio_buf + _audio_buf_index, available);
      requested -= available;
      _audio_buf_index += available;
      dst += available;
    }
  }
}

- (int)decodeAudio:(AudioBufferList*)buffer
{
  const int MAX_AUDIO_CHANNEL = 8;
  int channelNumber = buffer->mNumberBuffers;
  uint8_t* dst[MAX_AUDIO_CHANNEL];
  for (int i = 0; i < channelNumber; i++) {
      dst[i] = buffer->mBuffers[i].mData;
  }
  
  AVPacket *pkt_temp = &_audio_pkt_temp;
  AVPacket *pkt = &_audio_pkt;
  AVCodecContext *dec = _stream->codec;
  int len1, data_size, resampled_data_size;
  int64_t dec_channel_layout;
  int got_frame;
  int wanted_nb_samples;
  AVRational tb;
//  int ret;
//  int reconfigure;
  
  for (;;) {
    /* NOTE: the audio packet can contain several frames */
    while (pkt_temp->stream_index != -1 || _audio_buf_frames_pending) {
      if (!_frame) {
        if (!(_frame = av_frame_alloc()))
          return AVERROR(ENOMEM);
      } else {
        av_frame_unref(_frame);
      }
      
//      if (_audioq.serial != _audio_pkt_temp_serial)
//        break;
      
      if (_paused)
        return -1;
      
      if (!_audio_buf_frames_pending) {
        len1 = avcodec_decode_audio4(dec, _frame, &got_frame, pkt_temp);
        if (len1 < 0) {
          /* if error, we skip the frame */
          pkt_temp->size = 0;
          break;
        }
        
        pkt_temp->dts =
        pkt_temp->pts = AV_NOPTS_VALUE;
        pkt_temp->data += len1;
        pkt_temp->size -= len1;
        if ((pkt_temp->data && pkt_temp->size <= 0) || (!pkt_temp->data && !got_frame))
          pkt_temp->stream_index = -1;
        if (!pkt_temp->data && !got_frame)
          _audio_finished = _audio_pkt_temp_serial;
        
        if (!got_frame)
          continue;
        
        tb = (AVRational){1, _frame->sample_rate};
        if (_frame->pts != AV_NOPTS_VALUE)
          _frame->pts = av_rescale_q(_frame->pts, dec->time_base, tb);
        else if (_frame->pkt_pts != AV_NOPTS_VALUE)
          _frame->pts = av_rescale_q(_frame->pkt_pts, _stream->time_base, tb);
        else if (_audio_frame_next_pts != AV_NOPTS_VALUE)
          _frame->pts = av_rescale_q(_audio_frame_next_pts, (AVRational){1, _audio_src.freq}, tb);
        
        if (_frame->pts != AV_NOPTS_VALUE)
          _audio_frame_next_pts = _frame->pts + _frame->nb_samples;
        
      }
      
      data_size = av_samples_get_buffer_size(NULL, av_frame_get_channels(_frame),
                                             _frame->nb_samples,
                                             _frame->format, 1);
      
      dec_channel_layout =
      (_frame->channel_layout && av_frame_get_channels(_frame) == av_get_channel_layout_nb_channels(_frame->channel_layout)) ?
      _frame->channel_layout : av_get_default_channel_layout(av_frame_get_channels(_frame));
      wanted_nb_samples = _frame->nb_samples;
      
      if (_frame->format      != _audio_src.fmt            ||
          dec_channel_layout  != _audio_src.channel_layout ||
          _frame->sample_rate != _audio_src.freq           ||
          (wanted_nb_samples  != _frame->nb_samples && !_swr_ctx)) {
        swr_free(&_swr_ctx);
        _swr_ctx = swr_alloc_set_opts(NULL,
                                      _audio_tgt.channel_layout, _audio_tgt.fmt, _audio_tgt.freq,
                                      dec_channel_layout, _frame->format, _frame->sample_rate,
                                      0, NULL);
        if (!_swr_ctx || swr_init(_swr_ctx) < 0) {
          NSLog(@"Cannot create sample rate converter for conversion of %d Hz %s %d channels to %d Hz %s %d channels!\n",
                 _frame->sample_rate, av_get_sample_fmt_name(_frame->format), av_frame_get_channels(_frame),
                 _audio_tgt.freq, av_get_sample_fmt_name(_audio_tgt.fmt), _audio_tgt.channels);
          break;
        }
        _audio_src.channel_layout = dec_channel_layout;
        _audio_src.channels = av_frame_get_channels(_frame);
        _audio_src.freq = _frame->sample_rate;
        _audio_src.fmt = _frame->format;
      }
      
      if (_swr_ctx) {
        const uint8_t **in = (const uint8_t **)_frame->extended_data;
        uint8_t **out = &_audio_buf1;
        int out_count = (int)((int64_t)wanted_nb_samples * _audio_tgt.freq / _frame->sample_rate + 256);
        int out_size  = av_samples_get_buffer_size(NULL, _audio_tgt.channels, out_count, _audio_tgt.fmt, 0);
        int len2;
        if (out_size < 0) {
          NSLog(@"av_samples_get_buffer_size() failed\n");
          break;
        }
        if (wanted_nb_samples != _frame->nb_samples) {
          if (swr_set_compensation(_swr_ctx, (wanted_nb_samples - _frame->nb_samples) * _audio_tgt.freq / _frame->sample_rate,
                                   wanted_nb_samples * _audio_tgt.freq / _frame->sample_rate) < 0) {
            NSLog(@"swr_set_compensation() failed\n");
            break;
          }
        }
        av_fast_malloc(&_audio_buf1, &_audio_buf1_size, out_size);
        if (!_audio_buf1)
          return AVERROR(ENOMEM);
        len2 = swr_convert(_swr_ctx, out, out_count, in, _frame->nb_samples);
        if (len2 < 0) {
          NSLog(@"swr_convert() failed\n");
          break;
        }
        if (len2 == out_count) {
          NSLog(@"audio buffer is probably too small\n");
          swr_init(_swr_ctx);
        }
        _audio_buf = _audio_buf1;
        resampled_data_size = len2 * _audio_tgt.channels * av_get_bytes_per_sample(_audio_tgt.fmt);
      } else {
        _audio_buf = _frame->data[0];
        resampled_data_size = data_size;
      }
      
      /* update the audio clock with the pts */
      if (_frame->pts != AV_NOPTS_VALUE)
        _audio_clock = _frame->pts * av_q2d(tb) + (double) _frame->nb_samples / _frame->sample_rate;
      else
        _audio_clock = NAN;
      _audio_clock_serial = _audio_pkt_temp_serial;
      return resampled_data_size;
    }
    
    /* free the current packet */
    if (pkt->data)
      av_free_packet(pkt);
    memset(pkt_temp, 0, sizeof(*pkt_temp));
    pkt_temp->stream_index = -1;
    
//    if (_audioq.abort_request) {
//      return -1;
//    }
    
//    if (_audioq.nb_packets == 0)
//      SDL_CondSignal(_continue_read_thread);
    
    /* read next packet */
    if ([_decoder.audioQue isEmpty]) {
      return -1;
    }
    Packet* packet = [_decoder.audioQue get];
    pkt = packet.packet;

    if ([packet isFlush]) {
//      NSLog(@"audio flush");
      avcodec_flush_buffers(_stream->codec);
      _audio_buf_frames_pending = 0;
      _audio_frame_next_pts = AV_NOPTS_VALUE;
      if (![_decoder supportsSeek]) {
        _audio_frame_next_pts = _stream->start_time;
      }
    }

    *pkt_temp = *pkt;
  }
}

- (double)clock
{
  return _audio_clock;
}

@end
