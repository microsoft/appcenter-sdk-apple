/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAbstractErrorLog.h"
#import "SNMErrorAttachment.h"

static NSString *const kSNMId = @"id";
static NSString *const kSNMProcessId = @"process_id";
static NSString *const kSNMProcessName = @"process_name";
static NSString *const kSNMParentProcessId = @"parent_process_id";
static NSString *const kSNMParentProcessName = @"parent_process_name";
static NSString *const kSNMErrorThreadId = @"error_thread_id";
static NSString *const kSNMErrorThreadName = @"error_thread_name";
static NSString *const kSNMFatal = @"fatal";
static NSString *const kSNMAppLaunchTOffset = @"app_launch_toffset";
static NSString *const kSNMErrorAttachment = @"error_attachment";
static NSString *const kSNMArchitecture = @"architecture";

@implementation SNMAbstractErrorLog

@synthesize errorId = _id;
@synthesize processId = _processId;
@synthesize processName = _processName;
@synthesize parentProcessId = _parentProcessId;
@synthesize parentProcessName = _parentProcessName;
@synthesize errorThreadId = _errorThreadId;
@synthesize errorThreadName = _errorThreadName;
@synthesize fatal = _fatal;
@synthesize appLaunchTOffset = _appLaunchTOffset;
@synthesize errorAttachment = _errorAttachment;
@synthesize architecture = _architecture;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.errorId) {
    dict[kSNMId] = self.errorId;
  }
  if (self.processId) {
    dict[kSNMProcessId] = self.processId;
  }
  if (self.processName) {
    dict[kSNMProcessName] = self.processName;
  }
  if (self.parentProcessId) {
    dict[kSNMParentProcessId] = self.parentProcessId;
  }
  if (self.parentProcessName) {
    dict[kSNMParentProcessName] = self.parentProcessName;
  }
  if (self.errorThreadId) {
    dict[kSNMErrorThreadId] = self.errorThreadId;
  }
  if (self.errorThreadName) {
    dict[kSNMErrorThreadName] = self.errorThreadName;
  }
  if (self.fatal) {
    dict[kSNMFatal] = self.fatal ? @YES : @NO;
  }
  if (self.appLaunchTOffset) {
    dict[kSNMAppLaunchTOffset] = self.appLaunchTOffset;
  }
  if (self.errorAttachment) {
    dict[kSNMErrorAttachment] = self.errorAttachment;
  }
  if (self.architecture) {
    dict[kSNMArchitecture] = self.architecture;
  }

  return dict;
}

- (BOOL)isValid {
  return self.errorId && self.processId && self.processName && self.appLaunchTOffset;
}

- (BOOL)isEqual:(SNMAbstractErrorLog *)errorLog {
  if (!errorLog)
    return NO;

  return ((!self.errorId && !errorLog.errorId) || [self.errorId isEqualToString:errorLog.errorId]) &&
         ((!self.processId && !errorLog.processId) || [self.processId isEqual:errorLog.processId]) &&
         ((!self.processName && !errorLog.processName) || [self.processName isEqualToString:errorLog.processName]) &&
         ((!self.parentProcessId && !errorLog.parentProcessId) ||
          [self.parentProcessId isEqual:errorLog.parentProcessId]) &&
         ((!self.parentProcessName && !errorLog.parentProcessName) ||
          [self.parentProcessName isEqualToString:errorLog.parentProcessName]) &&
         ((!self.errorThreadId && !errorLog.errorThreadId) || [self.errorThreadId isEqual:errorLog.errorThreadId]) &&
         ((!self.errorThreadName && !errorLog.errorThreadName) ||
          [self.errorThreadName isEqualToString:errorLog.errorThreadName]) &&
         (self.fatal == errorLog.fatal) && ((!self.appLaunchTOffset && !errorLog.appLaunchTOffset) ||
                                            [self.appLaunchTOffset isEqual:errorLog.appLaunchTOffset]) &&
         ((!self.errorAttachment && !errorLog.errorAttachment) ||
          [self.errorAttachment isEqual:errorLog.errorAttachment]) &&
         ((!self.architecture && !errorLog.architecture) || [self.architecture isEqualToString:errorLog.architecture]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _id = [coder decodeObjectForKey:kSNMId];
    _processId = [coder decodeObjectForKey:kSNMProcessId];
    _processName = [coder decodeObjectForKey:kSNMProcessName];
    _parentProcessId = [coder decodeObjectForKey:kSNMParentProcessId];
    _parentProcessName = [coder decodeObjectForKey:kSNMParentProcessName];
    _errorThreadId = [coder decodeObjectForKey:kSNMErrorThreadId];
    _errorThreadName = [coder decodeObjectForKey:kSNMErrorThreadName];
    _fatal = [coder decodeBoolForKey:kSNMFatal];
    _appLaunchTOffset = [coder decodeObjectForKey:kSNMAppLaunchTOffset];
    _errorAttachment = [coder decodeObjectForKey:kSNMErrorAttachment];
    _architecture = [coder decodeObjectForKey:kSNMArchitecture];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.errorId forKey:kSNMId];
  [coder encodeObject:self.processId forKey:kSNMProcessId];
  [coder encodeObject:self.processName forKey:kSNMProcessName];
  [coder encodeObject:self.parentProcessId forKey:kSNMParentProcessId];
  [coder encodeObject:self.parentProcessName forKey:kSNMParentProcessName];
  [coder encodeObject:self.errorThreadId forKey:kSNMErrorThreadId];
  [coder encodeObject:self.errorThreadName forKey:kSNMErrorThreadName];
  [coder encodeBool:self.fatal forKey:kSNMFatal];
  [coder encodeObject:self.appLaunchTOffset forKey:kSNMAppLaunchTOffset];
  [coder encodeObject:self.errorAttachment forKey:kSNMErrorAttachment];
  [coder encodeObject:self.architecture forKey:kSNMArchitecture];
}

@end
