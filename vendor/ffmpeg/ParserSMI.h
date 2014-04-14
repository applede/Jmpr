//
//  ParserSMI.h
//  Jap
//
//  Created by Jake Song on 4/1/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Node : NSObject

@property NSString* name;
@property NSDictionary* attrs;
@property NSArray* children;

- (int64_t)time;
- (Node*)child:(NSString*)name;
- (NSString*)string;

@end

@interface ParserSMI : NSObject
{
  /// contents of file
  NSString* _str;
  /// current position
  int _pos;
  /// length of contents
  NSUInteger _length;
  /// current line number
  int _line;
  /// css classes
  NSMutableDictionary* _css;
  /// root node
  Node* _root;
}

- initPath:(NSString*)str;
- (NSArray*)nodes;

@end
