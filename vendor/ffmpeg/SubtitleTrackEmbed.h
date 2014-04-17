//
//  SubtitleTrackIn.h
//  Jap
//
//  Created by Jake Song on 3/31/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubtitleTrack.h"

@interface SubtitleTrackEmbed : SubtitleTrack
{
  BOOL _quit;
  CircularQueue* _frameQue;
  dispatch_queue_t _q;
  dispatch_semaphore_t _sema;
}

@end
