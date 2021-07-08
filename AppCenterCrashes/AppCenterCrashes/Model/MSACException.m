// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACException.h"
#import "MSACStackFrame.h"

static NSString *const kMSACExceptionFrames = @"frames";
static NSString *const kMSACExceptionType = @"type";
static NSString *const kMSACExceptionMessage = @"message";
static NSString *const kMSACExceptionStackTrace = @"stackTrace";

@implementation MSACException

- (instancetype)initWithException:(NSException *)exception {
  self = [super init];
  if (self) {
    if ([exception respondsToSelector:NSSelectorFromString(@"name")]) {
      self.type = exception.name;
    }
    if ([exception respondsToSelector:NSSelectorFromString(@"reason")]) {
      self.message = exception.reason;
    }
    if ([exception respondsToSelector:NSSelectorFromString(@"callStackSymbols")]) {
      self.stackTrace = exception.callStackSymbols.description;
    }
  }
  return self;
}

- (instancetype)initWithTypeAndMessage:(NSString *)exceptionType exceptionMessage:(NSString *)exceptionMessage {
  self = [super init];
  if (self) {
    self.type = exceptionType;
    self.message = exceptionMessage;
  }
  return self;
}

+ (MSACException *)convertNSErrorToMSACException:(NSError *)error {
  MSACException *msacException = [MSACException new];
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
    dict[kMSACExceptionType] = self.type;
  }
  if (self.message) {
    dict[kMSACExceptionMessage] = self.message;
  }
  if (self.stackTrace) {
    dict[kMSACExceptionStackTrace] = self.stackTrace;
  }
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (MSACStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kMSACExceptionFrames] = framesArray;
  }
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSACException class]]) {
    return NO;
  }
  MSACException *exception = (MSACException *)object;
  return ((!self.type && !exception.type) || [self.type isEqualToString:exception.type]) &&
         ((!self.message && !exception.message) || [self.message isEqualToString:exception.message]) &&
         ((!self.frames && !exception.frames) || [self.frames isEqualToArray:exception.frames]) &&
         ((!self.stackTrace && !exception.stackTrace) || [self.stackTrace isEqualToString:exception.stackTrace]);
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  self = [super init];
  if (self) {
    self.type = [coder decodeObjectForKey:kMSACExceptionType];
    self.message = [coder decodeObjectForKey:kMSACExceptionMessage];
    self.stackTrace = [coder decodeObjectForKey:kMSACExceptionStackTrace];
    self.frames = [coder decodeObjectForKey:kMSACExceptionFrames];
  }
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSACExceptionType];
  [coder encodeObject:self.message forKey:kMSACExceptionMessage];
  [coder encodeObject:self.stackTrace forKey:kMSACExceptionStackTrace];
  [coder encodeObject:self.frames forKey:kMSACExceptionFrames];
}

@end
