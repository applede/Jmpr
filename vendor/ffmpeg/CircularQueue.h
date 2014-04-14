//
//  CircularQueue.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CircularQueue : NSObject
{
  int _size;
  int _count;
  int _front;
  int _back;
  id __strong* _objs;
  NSLock* _lock;
}

@property (readonly) int count;

- initSize:(int)size;
- (int)count;

- (BOOL)isEmpty;
- (BOOL)isFull;

- front;
- back;

- (void)put:obj;
- (void)advance;
- get;
- (void)flush;

- objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:obj atIndexedSubscript:(NSUInteger)idx;

@end
