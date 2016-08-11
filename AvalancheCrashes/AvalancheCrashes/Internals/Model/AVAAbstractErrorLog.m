/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAbstractErrorLog.h"

static NSString *const kAVAErrorId = @"errorId";
static NSString *const kAVAProcessId = @"processId";
static NSString *const kAVAProcessName = @"processName";
static NSString *const kAVAParentProcessId = @"parentProcessId";
static NSString *const kAVAParentProcessName = @"parentProcessName";
static NSString *const kAVAFatal = @"fatal";
static NSString *const kAVAAppLaunchTOffset = @"appLaunchTOffset";
static NSString *const kAVAErrorThreadId = @"errorThreadId";
static NSString *const kAVAErrorThreadName = @"errorThreadName";

@implementation AVAAbstractErrorLog

@synthesize type = _type;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.toffset) {
    // TODO what about toffset and sid?
  }

  if (self.errorId) {
    dict[kAVAErrorId] = self.errorId;
  }
  if (self.processId) {
    dict[kAVAProcessId] = self.processId;
  }
  if (self.processName) {
    dict[kAVAProcessName] = self.processName;
  }
  if (self.parentProcessId) {
    dict[kAVAParentProcessId] = self.parentProcessId;
  }
  if (self.parentProcessName) {
    dict[kAVAParentProcessName] = self.parentProcessName;
  }
  if (self.fatal) {
    dict[kAVAFatal] = self.fatal;
  }
  if (self.appLaunchTOffset) {
    dict[kAVAAppLaunchTOffset] = self.appLaunchTOffset;
  }
  if (self.errorThreadId) {
    dict[kAVAErrorThreadId] = self.errorThreadId;
  }
  if (self.errorThreadName) {
    dict[kAVAErrorThreadName] = self.errorThreadName;
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    // TODO what about toffset and sid?
    _type = [coder decodeObjectForKey:kAVAType];
    _errorId = [coder decodeObjectForKey:kAVAErrorId];
    _processId = [coder decodeObjectForKey:kAVAProcessId];
    _processName = [coder decodeObjectForKey:kAVAProcessName];
    _parentProcessId = [coder decodeObjectForKey:kAVAParentProcessId];
    _parentProcessName = [coder decodeObjectForKey:kAVAParentProcessName];
    _fatal = [coder decodeObjectForKey:kAVAFatal];
    _appLaunchTOffset = [coder decodeObjectForKey:kAVAAppLaunchTOffset];
    _errorThreadId = [coder decodeObjectForKey:kAVAErrorThreadId];
    _errorThreadName = [coder decodeObjectForKey:kAVAErrorThreadName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  // TODO what about toffset and sid?
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.errorId forKey:kAVAErrorId];
  [coder encodeObject:self.processId forKey:kAVAProcessId];
  [coder encodeObject:self.processName forKey:kAVAProcessName];
  [coder encodeObject:self.parentProcessId forKey:kAVAParentProcessId];
  [coder encodeObject:self.parentProcessName forKey:kAVAParentProcessName];
  [coder encodeObject:self.fatal forKey:kAVAFatal];
  [coder encodeObject:self.appLaunchTOffset forKey:kAVAAppLaunchTOffset];
  [coder encodeObject:self.errorThreadId forKey:kAVAErrorThreadId];
  [coder encodeObject:self.errorThreadName forKey:kAVAErrorThreadName];
}

@end
