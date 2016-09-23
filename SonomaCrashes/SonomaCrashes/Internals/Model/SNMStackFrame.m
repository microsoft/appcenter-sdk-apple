/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMStackFrame.h"

static NSString *const kSNMAddress = @"address";
static NSString *const kSNMCode = @"code";
static NSString *const kSNMClassName = @"class_name";
static NSString *const kSNMMethodName = @"method_name";
static NSString *const kSNMLineNumber = @"line_number";
static NSString *const kSNMFileName = @"file_name";

@implementation SNMStackFrame

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.address) {
    dict[kSNMAddress] = self.address;
  }
  if (self.code) {
    dict[kSNMCode] = self.code;
  }
  if (self.className) {
    dict[kSNMClassName] = self.className;
  }
  if (self.methodName) {
    dict[kSNMMethodName] = self.methodName;
  }
  if (self.lineNumber) {
    dict[kSNMLineNumber] = self.lineNumber;
  }
  if (self.fileName) {
    dict[kSNMFileName] = self.fileName;
  }
  return dict;
}

- (BOOL)isEqual:(SNMStackFrame *)frame {
  if (!frame)
    return NO;

  return ((!self.address && !frame.address) || [self.address isEqualToString:frame.address]) &&
         ((!self.code && !frame.code) || [self.code isEqualToString:frame.code]) &&
         ((!self.className && !frame.className) || [self.className isEqualToString:frame.className]) &&
         ((!self.methodName && !frame.methodName) || [self.methodName isEqualToString:frame.methodName]) &&
         ((!self.lineNumber && !frame.lineNumber) || [self.lineNumber isEqual:frame.lineNumber]) &&
         ((!self.fileName && !frame.fileName) || [self.fileName isEqualToString:frame.fileName]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _address = [coder decodeObjectForKey:kSNMAddress];
    _code = [coder decodeObjectForKey:kSNMCode];
    _className = [coder decodeObjectForKey:kSNMClassName];
    _methodName = [coder decodeObjectForKey:kSNMMethodName];
    _lineNumber = [coder decodeObjectForKey:kSNMLineNumber];
    _fileName = [coder decodeObjectForKey:kSNMFileName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.address forKey:kSNMAddress];
  [coder encodeObject:self.code forKey:kSNMCode];
  [coder encodeObject:self.className forKey:kSNMClassName];
  [coder encodeObject:self.methodName forKey:kSNMMethodName];
  [coder encodeObject:self.lineNumber forKey:kSNMLineNumber];
  [coder encodeObject:self.fileName forKey:kSNMFileName];
}

@end
