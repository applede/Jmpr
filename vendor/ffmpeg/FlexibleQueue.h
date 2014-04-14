//
//  Queue.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Time

- (double)time;

@end

/// It allows to put elements even if it is full.

@interface FlexibleQueue : NSObject
{
  int _size;
  NSMutableArray* _array;
  NSLock* _lock;
}

- initSize:(int)size;
- (NSUInteger)count;
- (BOOL)isFull;
- (BOOL)isEmpty;
- front;
- (void)add:(id<Time>)element;
- get;
- getBefore:(double)time;
- (void)flush;

@end
