// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACExceptionModel.h"
#import "MSACStackFrame.h"

@implementation MSACExceptionModel

- (instancetype)initWithTypeAndMessage:(NSString *)exceptionType exceptionMessage:(NSString *)exceptionMessage {
  self = [super init];
  if (self) {
    self.type = exceptionType;
    self.message = exceptionMessage;
  }
  return self;
}

+ (MSACExceptionModel *)convertNSErrorToMSACExceptionModel:(NSError *)error {
  MSACExceptionModel *msacException = [MSACExceptionModel new];
  if (error.domain) {
    msacException.type = error.domain;
  }
  if (error.userInfo && error.userInfo.count > 0) {
    msacException.message = error.userInfo.description;
  }
  msacException.stackTrace = [[NSThread callStackSymbols] description];
  return msacException;
}

- (BOOL)isValid {
  return MSACLOG_VALIDATE_NOT_NIL(type) && MSACLOG_VALIDATE(frames, [self.frames count] > 0);
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.type) {
    dict[kMSACExceptionModelType] = self.type;
  }
  if (self.message) {
    dict[kMSACExceptionModelMessage] = self.message;
  }
  if (self.stackTrace) {
    dict[kMSACExceptionModelStackTrace] = self.stackTrace;
  }
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (MSACStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kMSACExceptionModelFrames] = framesArray;
  }
  return dict;
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  self = [super init];
  if (self) {
    self.type = [coder decodeObjectForKey:kMSACExceptionModelType];
    self.message = [coder decodeObjectForKey:kMSACExceptionModelMessage];
    self.stackTrace = [coder decodeObjectForKey:kMSACExceptionModelStackTrace];
    self.frames = [coder decodeObjectForKey:kMSACExceptionModelFrames];
  }
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSACExceptionModelType];
  [coder encodeObject:self.message forKey:kMSACExceptionModelMessage];
  [coder encodeObject:self.stackTrace forKey:kMSACExceptionModelStackTrace];
  [coder encodeObject:self.frames forKey:kMSACExceptionModelFrames];
}

@end
