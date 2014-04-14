//
//  ParserSMI.m
//  Jap
//
//  Created by Jake Song on 4/1/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "ParserSMI.h"

typedef enum {
  WORD = 1,
  STRING,
  NUMBER,
  COMMENT_START,
  COMMENT_END,
  TAG,
  TAG_END,
  END = (unichar)-1
} Token;

NSString* tokenString(int token)
{
  switch (token) {
    case WORD:
      return @"WORD";
    case STRING:
      return @"STRING";
    case COMMENT_START:
      return @"<!--";
    case COMMENT_END:
      return @"-->";
    case TAG:
      return @"<";
    case TAG_END:
      return @"</";
    case END:
      return @"EOF";
    default:
      return [NSString stringWithFormat:@"%c", token];
  }
}

BOOL isWhiteSpace(unichar c)
{
  return c == ' ' || c == '\n' || c == '\r' || c == '\t';
}

BOOL isAlpha(unichar c)
{
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

BOOL isDigit(unichar c)
{
  return (c >= '0' && c <= '9');
}

@implementation Node

- (int64_t)time
{
  return [self.attrs[@"Start"] longLongValue];
}

- (NSString*)string
{
  return [[self child:@"P"].children componentsJoinedByString:@"\n"];
}

- (Node*)child:(NSString *)name
{
  __block Node* child = nil;
  [self.children enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL* stop) {
    if ([[obj name] isEqualToString:name]) {
      child = obj;
      *stop = YES;
    }
  }];
  return child;
}

- (NSString*)description
{
  NSMutableString* desc = [NSMutableString stringWithFormat:@"<%@", self.name];
  [self.attrs enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
    [desc appendFormat:@" %@=%@", key, value];
  }];
  [desc appendString:@">"];
  return desc;
}

- (void)print
{
  NSLog(@"%@", self);
  if (self.children) {
    [self.children enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL* stop) {
      if ([obj isKindOfClass:[Node class]]) {
        [obj print];
      } else {
        NSLog(@"%@", obj);
      }
    }];
  }
  NSLog(@"</%@>", self.name);
}

@end

@implementation ParserSMI

- initPath:(NSString*)path
{
  self = [super init];
  if (self) {
    NSData* data = [NSData dataWithContentsOfFile:path];
    if (data) {
      NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSKorean);
      NSString* str = [[NSString alloc] initWithData:data encoding:encoding];
      if (str) {
        if ([self parse:str]) {
          return self;
        }
      }
    }
  }
  return nil;
}

- (NSArray *)nodes
{
  return [[_root child:@"SAMI"] child:@"BODY"].children;
}

- (BOOL)parse:(NSString*)str
{
  _str = str;
  _pos = 0;
  _length = [_str length];
  _line = 1;
  _css = [[NSMutableDictionary alloc] init];

  _root = [[Node alloc] init];
  _root.children = [self parseUntil:nil];
  return YES;
}

- (void)parseStyle
{
  if (![self skip:COMMENT_START]) {
    return;
  }
  if (![self expect:WORD value:@"P"]) {
    return;
  }
  if (![self skipBlock]) {
    return;
  }
  if (![self skip:'.']) {
    return;
  }
  NSString* className;
  if (![self get:WORD value:&className]) {
    return;
  }
  NSDictionary* attrs = [self parseCSSAttributes];
  if (attrs) {
    _css[className] = attrs;
  }
  if (![self skip:COMMENT_END]) {
    return;
  }
  if (![self expect:TAG_END value:@"STYLE"]) {
    return;
  }
}

- (NSDictionary*)parseCSSAttributes
{
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  if (![self skip:'{']) {
    return nil;
  }
  for (;;) {
    NSString* key;
    int token = [self getToken:&key];
    if (token == '}') {
      return dict;
    }
    if (token != WORD) {
      [self error:@"expected attribute name, got %@", tokenString(token)];
      return nil;
    }
    if (![self skip:':']) {
      return nil;
    }
    NSString* value;
    if (![self get:WORD value:&value]) {
      return nil;
    }
    if (![self skip:';']) {
      return nil;
    }
    dict[key] = value;
  }
 
  return dict;
}

- (NSArray*)parseUntil:(NSString*)tagName
{
  NSMutableArray* array = [[NSMutableArray alloc] init];
  NSString* value;
  while (YES) {
    int orig = _pos;
    int token = [self getToken:&value];
    if (token == TAG) {
      if (([tagName isEqualToString:@"P"] || [tagName isEqualToString:@"SYNC"]) &&
          [value isEqualToString:@"SYNC"]) {
        // auto close, put back token
        _pos = orig;
        return array;
      } else if ([value isEqualToString:@"br"]) {
        [self skip:'>'];
      } else {
        Node* node = [[Node alloc] init];
        node.name = value;
        node.attrs = [self getAttributes];
        if ([value isEqualToString:@"STYLE"]) {
          [self parseStyle];
        } else {
          node.children = [self parseUntil:value];
        }
        [array addObject:node];
      }
    } else if (token == TAG_END) {
      if (([tagName isEqualToString:@"P"] || [tagName isEqualToString:@"SYNC"]) &&
          [value isEqualToString:@"BODY"]) {
        // auto close, put back token
        _pos = orig;
        return array;
      }
      if ([value isEqualToString:tagName]) {
        return array;
      } else {
        [self error:@"unexpected closing tag %@", value];
        return nil;
      }
    } else if (token == COMMENT_START) {
      [self skipUpto:COMMENT_END];
    } else if (token == END) {
      return array;
    } else {
      // put back character
      _pos = orig;
      [self skipWhiteSpace];
      NSString* s = [self getBefore:'<'];
      s = [self convert:s];
      [array addObject:s];
    }
  }
}

- (NSDictionary*)getAttributes
{
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  NSString* key;
  while (_pos < _length) {
    int token = [self getToken:&key];
    if (token == WORD) {
      NSString* value;
      token = [self getToken:&value];
      if (token == '=') {
        token = [self getToken:&value];
        if (token == STRING || token == WORD || token == NUMBER) {
          dict[key] = value;
        } else {
          [self error:@"expected string or word, got %c", token];
          return nil;
        }
      } else {
        [self error:@"expected '=', got %c", token];
        return nil;
      }
    } else if (token == '>') {
      return dict;
    }
  }
  return nil;
}

- (BOOL)skipBlock
{
  if ([self skip:'{']) {
    if ([self skipUpto:'}']) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)skipUpto:(int)t
{
  NSString* value;
  int token = [self getToken:&value];
  while (token != t && token != END) {
    token = [self getToken:&value];
  }
  if (token == END) {
    [self error:@"expected %@, got %@", tokenString(t), tokenString(token)];
    return NO;
  }
  return YES;
}

- (BOOL)expect:(int)tag value:(NSString*)expected
{
  NSString* value;
  if (![self get:tag value:&value]) {
    return NO;
  }
  if (![value isEqualToString:expected]) {
    [self error:@"expected %@, got %@", expected, value];
    return NO;
  }
  return YES;
}

- (BOOL)skip:(int)t
{
  return [self get:t value:nil];
}

- (BOOL)get:(int)t value:(NSString**)value
{
  int token = [self getToken:value];
  if (token == t) {
    return YES;
  }
  [self error:@"expected %@, got %@", tokenString(t), tokenString(token)];
  return NO;
}

- (int)getToken:(NSString**)value
{
  unichar c = [self skipWhiteSpace];
  if (isAlpha(c)) {
    NSString* v = [self getWord];
    if (value) {
      *value = v;
    }
    return WORD;
  } else if (isDigit(c)) {
    NSString* v = [self getNumber];
    if (value) {
      *value = v;
    }
    return NUMBER;
  } else if (c == '"') {
    _pos++;
    NSString* v = [self getUntil:'"'];
    if (value) {
      *value = v;
    }
    return STRING;
  } else if (c == '<') {
    if ([self skipString:@"<!--"]) {
      return COMMENT_START;
    } else {
      _pos++;
      c = [_str characterAtIndex:_pos];
      if (c == '/') {
        _pos++;
        NSString* tagName = [self getWord];
        if (value) {
          *value = tagName;
        }
        if ([self skipString:@">"]) {
          return TAG_END;
        }
        [self error:@"invalid tag"];
        return END;
      } else if (isAlpha(c)) {
        NSString* tagName = [self getWord];
        if (value) {
          *value = tagName;
        }
        return TAG;
      } else {
        [self error:@"invalid tag %c", c];
        return END;
      }
    }
  } else if (c == '-') {
    if ([self skipString:@"-->"]) {
      return COMMENT_END;
    }
  } else if (c == END) {
    return END;
  }
  
  _pos++;
  return c;
}

- (NSString*)getUntil:(unichar)ch
{
  NSString* s = [self getBefore:ch];
  _pos++;
  return s;
}

- (NSString*)getBefore:(unichar)ch
{
  int start = _pos;
  while ([_str characterAtIndex:_pos] != ch) {
    _pos++;
  }
  return [_str substringWithRange:NSMakeRange(start, _pos - start)];
}

- (NSString*)getWordSkipWhiteSpace
{
  [self skipWhiteSpace];
  return [self getWord];
}

- (NSString*)getWord
{
  unichar c = [_str characterAtIndex:_pos];
  int start = _pos;
  if (isAlpha(c)) {
    _pos++;
    c = [_str characterAtIndex:_pos];
    while (isAlpha(c) || c == '-') {
      _pos++;
      c = [_str characterAtIndex:_pos];
    }
  }
  if (_pos > start) {
    return [_str substringWithRange:NSMakeRange(start, _pos - start)];
  }
  return nil;
}

- (NSString*)getNumber
{
  unichar c = [_str characterAtIndex:_pos];
  int start = _pos;
  while (isDigit(c)) {
    _pos++;
    c = [_str characterAtIndex:_pos];
  }
  if (_pos > start) {
    return [_str substringWithRange:NSMakeRange(start, _pos - start)];
  }
  return nil;
}

- (BOOL)skipString:(NSString*)str
{
  NSUInteger len = [str length];
  if ([[_str substringWithRange:NSMakeRange(_pos, len)] isEqualToString:str]) {
    _pos += len;
    return YES;
  }
  return NO;
}

- (unichar)skipWhiteSpace
{
  while (_pos < _length) {
    unichar c = [_str characterAtIndex:_pos];
    if (isWhiteSpace(c)) {
      if (c == '\n') {
        _line++;
      }
      _pos++;
    } else {
      return c;
    }
  }
  return END;
}

- (NSString*)convert:(NSString*)s
{
  NSRange r = [s rangeOfString:@"&nbsp;"];
  if (r.location == NSNotFound) {
    return s;
  }
  NSMutableString* ms = [NSMutableString stringWithString:s];
  [ms replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:0
                           range:NSMakeRange(0, [ms length])];
  return ms;
}

- (void)error:(NSString*)format, ...
{
  va_list args;
  va_start(args, format);
  NSString* formatStr = [NSString stringWithFormat:@"line %d: %@", _line, format];
  NSLogv(formatStr, args);
  va_end(args);
}

@end
