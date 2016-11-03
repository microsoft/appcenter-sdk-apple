/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAbstractErrorLog.h"
#import "MSErrorAttachment.h"
#import "MSErrorAttachmentPrivate.h"

static NSString *const kMSId = @"id";
static NSString *const kMSProcessId = @"process_id";
static NSString *const kMSProcessName = @"process_name";
static NSString *const kMSParentProcessId = @"parent_process_id";
static NSString *const kMSParentProcessName = @"parent_process_name";
static NSString *const kMSErrorThreadId = @"error_thread_id";
static NSString *const kMSErrorThreadName = @"error_thread_name";
static NSString *const kMSFatal = @"fatal";
static NSString *const kMSAppLaunchTOffset = @"app_launch_toffset";
static NSString *const kMSErrorAttachment = @"error_attachment";
static NSString *const kMSArchitecture = @"architecture";

@implementation MSAbstractErrorLog

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
    dict[kMSId] = self.errorId;
  }
  if (self.processId) {
    dict[kMSProcessId] = self.processId;
  }
  if (self.processName) {
    dict[kMSProcessName] = self.processName;
  }
  if (self.parentProcessId) {
    dict[kMSParentProcessId] = self.parentProcessId;
  }
  if (self.parentProcessName) {
    dict[kMSParentProcessName] = self.parentProcessName;
  }
  if (self.errorThreadId) {
    dict[kMSErrorThreadId] = self.errorThreadId;
  }
  if (self.errorThreadName) {
    dict[kMSErrorThreadName] = self.errorThreadName;
  }
  if (self.fatal) {
    dict[kMSFatal] = self.fatal ? @YES : @NO;
  }
  if (self.appLaunchTOffset) {
    dict[kMSAppLaunchTOffset] = self.appLaunchTOffset;
  }
  if (self.errorAttachment) {
    dict[kMSErrorAttachment] = [self.errorAttachment serializeToDictionary];
  }
  if (self.architecture) {
    dict[kMSArchitecture] = self.architecture;
  }

  return dict;
}

- (BOOL)isValid {
  return self.errorId && self.processId && self.processName && self.appLaunchTOffset;
}

- (BOOL)isEqual:(MSAbstractErrorLog *)errorLog {
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
    _id = [coder decodeObjectForKey:kMSId];
    _processId = [coder decodeObjectForKey:kMSProcessId];
    _processName = [coder decodeObjectForKey:kMSProcessName];
    _parentProcessId = [coder decodeObjectForKey:kMSParentProcessId];
    _parentProcessName = [coder decodeObjectForKey:kMSParentProcessName];
    _errorThreadId = [coder decodeObjectForKey:kMSErrorThreadId];
    _errorThreadName = [coder decodeObjectForKey:kMSErrorThreadName];
    _fatal = [coder decodeBoolForKey:kMSFatal];
    _appLaunchTOffset = [coder decodeObjectForKey:kMSAppLaunchTOffset];
    _errorAttachment = [coder decodeObjectForKey:kMSErrorAttachment];
    _architecture = [coder decodeObjectForKey:kMSArchitecture];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.errorId forKey:kMSId];
  [coder encodeObject:self.processId forKey:kMSProcessId];
  [coder encodeObject:self.processName forKey:kMSProcessName];
  [coder encodeObject:self.parentProcessId forKey:kMSParentProcessId];
  [coder encodeObject:self.parentProcessName forKey:kMSParentProcessName];
  [coder encodeObject:self.errorThreadId forKey:kMSErrorThreadId];
  [coder encodeObject:self.errorThreadName forKey:kMSErrorThreadName];
  [coder encodeBool:self.fatal forKey:kMSFatal];
  [coder encodeObject:self.appLaunchTOffset forKey:kMSAppLaunchTOffset];
  [coder encodeObject:self.errorAttachment forKey:kMSErrorAttachment];
  [coder encodeObject:self.architecture forKey:kMSArchitecture];
}

@end
