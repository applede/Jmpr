//
//  CircularQueue.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "CircularQueue.h"

@implementation CircularQueue

- initSize:(int)size
{
  self = [super init];
  if (self) {
    _size = size;
    _count = 0;
    _front = 0;
    _back = 0;
    _objs = (id __strong*)calloc(_size, sizeof(id));
    _lock = [[NSLock alloc] init];
  }
  return self;
}

-(void)dealloc
{
  for (int i = 0; i < _size; i++) {
    _objs[i] = nil;
  }
}

- (int)count
{
  return _count;
}

- (BOOL)isEmpty
{
  BOOL r;
  [_lock lock];
  r = (_count == 0);
  [_lock unlock];
  return r;
}

- (BOOL)isFull
{
  BOOL r;
  [_lock lock];
  r = (_count >= _size);
  [_lock unlock];
  return r;
}

- (id)front
{
  [_lock lock];
  id r = _objs[_front];
  [_lock unlock];
  return r;
}

- (id)back
{
  [_lock lock];
  id r = _objs[_back];
  [_lock unlock];
  return r;
}

- (void)put:obj
{
  assert(_count < _size);
  [_lock lock];
  _objs[_back] = obj;
  _back = (_back + 1) % _size;
  _count++;
  [_lock unlock];
}

- (void)advance
{
  [_lock lock];
  _back = (_back + 1) % _size;
  _count++;
  [_lock unlock];
}

- get
{
  assert(_count > 0);
  id obj;
  [_lock lock];
  obj = _objs[_front];
  _front = (_front + 1) % _size;
  _count--;
  [_lock unlock];
  return obj;
}

- (void)flush
{
  [_lock lock];
  // don't destroy _objs
  _front = _back;
  _count = 0;
  [_lock unlock];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)i
{
  [_lock lock];
  _objs[i] = obj;
  [_lock unlock];
}

- (id)objectAtIndexedSubscript:(NSUInteger)i
{
  id r;
  [_lock lock];
  r = _objs[i];
  [_lock unlock];
  return r;
}

@end
