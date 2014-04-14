//
//  Decoder.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "VideoTrackCPU.h"
#import "VideoTrackGPU.h"
#import "AudioTrack.h"
#import "SubtitleTrack.h"
#import "SubtitleTrackEmbed.h"
#import "SubtitleTrackSMI.h"
#import "CircularQueue.h"

@interface Decoder : NSObject
{
  NSString* _path;
  
  BOOL _quit;
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  AVFormatContext *_formatContext;
  int _videoStream;
  int _audioStream;
  int _subtitleStream;
  
  AudioTrack* _audioTrack;

  int64_t _seekPos;
  int64_t _seekInc;
  BOOL _seekReq;
}

@property (readonly) CircularQueue* videoQue;
@property (readonly) CircularQueue* audioQue;
@property (readonly) CircularQueue* subtitleQue;
@property (readonly) VideoTrack* videoTrack;
@property (readonly) SubtitleTrack* subtitleTrack;

- (void)open:(NSString*)path;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;

- (void)seek:(double)inc;
- (BOOL)supportsSeek;

- (void)checkQue;
- (double)masterClock;
- (NSString*)subtitleString;

@end
