/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAStackFrame.h"

static NSString *const kAVAAddress = @"address";
static NSString *const kAVACode = @"code";
static NSString *const kAVAClassName = @"className";
static NSString *const kAVAMethodName = @"methodName";
static NSString *const kAVALineNumber = @"lineNumber";
static NSString *const kAVAFileName = @"fileName";

@implementation AVAStackFrame

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.address) {
    dict[kAVAAddress] = self.address;
  }
  if (self.code) {
    dict[kAVACode] = self.code;
  }
  if (self.className) {
    dict[kAVAClassName] = self.className;
  }
  if (self.methodName) {
    dict[kAVAMethodName] = self.methodName;
  }
  if (self.lineNumber) {
    dict[kAVALineNumber] = self.lineNumber;
  }
  if (self.fileName) {
    dict[kAVAFileName] = self.fileName;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _address = [coder decodeObjectForKey:kAVAAddress];
    _code = [coder decodeObjectForKey:kAVACode];
    _className = [coder decodeObjectForKey:kAVAClassName];
    _methodName = [coder decodeObjectForKey:kAVAMethodName];
    _lineNumber = [coder decodeObjectForKey:kAVALineNumber];
    _fileName = [coder decodeObjectForKey:kAVAFileName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.address forKey:kAVAAddress];
  [coder encodeObject:self.code forKey:kAVACode];
  [coder encodeObject:self.className forKey:kAVAClassName];
  [coder encodeObject:self.methodName forKey:kAVAMethodName];
  [coder encodeObject:self.lineNumber forKey:kAVALineNumber];
  [coder encodeObject:self.fileName forKey:kAVAFileName];
}

@end
