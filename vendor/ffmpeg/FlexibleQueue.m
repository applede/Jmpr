//
//  Queue.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "FlexibleQueue.h"

@implementation FlexibleQueue

- (id)initSize:(int)size
{
  self = [super init];
  if (self) {
    _size = size;
    _array = [[NSMutableArray alloc] initWithCapacity:_size];
    _lock = [[NSLock alloc] init];
  }
  return self;
}

- (NSUInteger)count
{
  return [_array count];
}

- (BOOL)isEmpty
{
  BOOL r;
  [_lock lock];
  r = [_array count] == 0;
  [_lock unlock];
  return r;
}

- (BOOL)isFull
{
  BOOL r;
  [_lock lock];
  r = [_array count] >= _size;
  [_lock unlock];
  return r;
}

- (id)front
{
  id r;
  [_lock lock];
  r = [_array objectAtIndex:0];
  [_lock unlock];
  return r;
}

- (void)add:(id<Time>)element
{
  [_lock lock];
  int i = 0;
  for (; i < [_array count]; i++) {
    if ([[_array objectAtIndex:i] time] > [element time]) {
      break;
    }
  }
  [_array insertObject:element atIndex:i];
  [_lock unlock];
}

- get
{
  id r;
  [_lock lock];
  r = [_array objectAtIndex:0];
  [_array removeObjectAtIndex:0];
  [_lock unlock];
  return r;
}

- getBefore:(double)t
{
  id<Time> r = nil;
  [_lock lock];
  r = [_array objectAtIndex:0];
  if ([r time] <= t) {
    [_array removeObjectAtIndex:0];
  } else {
    r = nil;
  }
  [_lock unlock];
  return r;
}

- (void)flush
{
  [_lock lock];
  [_array removeAllObjects];
  [_lock unlock];
}

@end
