//
//  SubtitleTrackSMI.h
//  Jap
//
//  Created by Jake Song on 3/31/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubtitleTrack.h"

@class Decoder;

@interface SubtitleTrackSMI : SubtitleTrack
{
  NSArray* _nodes;
  int _current;
  double _lastTime;
}

- initDecoder:(Decoder*)decoder stream:(AVStream*)stream path:(NSString*)path;

@end
