/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorLog.h"

static NSString *const kAVATypeError = @"error";

static NSString *const kAVAId = @"id";
static NSString *const kAVAProcess = @"process";
static NSString *const kAVAProcessId = @"processId";
static NSString *const kAVAParentProcess = @"parentProcess";
static NSString *const kAVAParentProcessId = @"parentProcessId";
static NSString *const kAVACrashThread = @"crashThread";
static NSString *const kAVAApplicationPath = @"applicationPath";
static NSString *const kAVAAppLaunchTOffset = @"appLaunchTOffset";
static NSString *const kAVAExceptionType = @"exceptionType";
static NSString *const kAVAExceptionCode = @"exceptionCode";
static NSString *const kAVAExceptionAddress = @"exceptionAddress";
static NSString *const kAVAExceptionReason = @"exceptionReason";
static NSString *const kAVAFatal = @"fatal";
static NSString *const kAVAThreads = @"threads";
static NSString *const kAVAExceptions = @"exceptions";
static NSString *const kAVABinaries = @"binaries";

@implementation AVAErrorLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type= kAVATypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  
  if (self.crashId) {
    dict[kAVAId] = self.crashId;
  }
  if (self.process) {
    dict[kAVAProcess] = self.process;
  }
  if (self.processId) {
    dict[kAVAProcessId] = self.processId;
  }
  if (self.parentProcess) {
    dict[kAVAParentProcess] = self.parentProcess;
  }
  if (self.parentProcessId) {
    dict[kAVAParentProcessId] = self.parentProcessId;
  }
  if (self.crashThread) {
    dict[kAVACrashThread] = self.crashThread;
  }
  if (self.applicationPath) {
    dict[kAVAApplicationPath] = self.applicationPath;
  }
  if (self.appLaunchTOffset) {
    dict[kAVAAppLaunchTOffset] = self.appLaunchTOffset;
  }
  if (self.exceptionType) {
    dict[kAVAExceptionType] = self.exceptionType;
  }
  if (self.exceptionCode) {
    dict[kAVAExceptionCode] = self.exceptionCode;
  }
  if (self.exceptionAddress) {
    dict[kAVAExceptionAddress] = self.exceptionAddress;
  }
  if (self.exceptionReason) {
    dict[kAVAExceptionReason] = self.exceptionReason;
  }
  if (self.fatal) {
    dict[kAVAFatal] = self.fatal;
  }
  if (self.threads) {
    dict[kAVAThreads] = self.threads;
  }
  if (self.exceptions) {
    dict[kAVAExceptions] = self.exceptions;
  }
  if (self.binaries) {
    dict[kAVABinaries] = self.binaries;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if(self) {
    _type = [coder decodeObjectForKey:kAVAType];
    _crashId = [coder decodeObjectForKey:kAVAId];
    _process = [coder decodeObjectForKey:kAVAProcess];
    _processId = [coder decodeObjectForKey:kAVAProcessId];
    _parentProcess = [coder decodeObjectForKey:kAVAParentProcess];
    _parentProcessId = [coder decodeObjectForKey:kAVAParentProcessId];
    _crashThread = [coder decodeObjectForKey:kAVACrashThread];
    _applicationPath = [coder decodeObjectForKey:kAVAApplicationPath];
    _appLaunchTOffset = [coder decodeObjectForKey:kAVAAppLaunchTOffset];
    _exceptionType = [coder decodeObjectForKey:kAVAExceptionType];
    _exceptionCode = [coder decodeObjectForKey:kAVAExceptionCode];
    _exceptionAddress = [coder decodeObjectForKey:kAVAExceptionAddress];
    _exceptionReason = [coder decodeObjectForKey:kAVAExceptionReason];
    _fatal = [coder decodeObjectForKey:kAVAFatal];
    _threads = [coder decodeObjectForKey:kAVAThreads];
    _exceptions = [coder decodeObjectForKey:kAVAExceptions];
    _binaries = [coder decodeObjectForKey:kAVABinaries];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.crashId forKey:kAVAId];
  [coder encodeObject:self.process forKey:kAVAProcess];
  [coder encodeObject:self.processId forKey:kAVAProcessId];
  [coder encodeObject:self.parentProcess forKey:kAVAParentProcess];
  [coder encodeObject:self.parentProcessId forKey:kAVAParentProcessId];
  [coder encodeObject:self.crashThread forKey:kAVACrashThread];
  [coder encodeObject:self.applicationPath forKey:kAVAApplicationPath];
  [coder encodeObject:self.appLaunchTOffset forKey:kAVAAppLaunchTOffset];
  [coder encodeObject:self.exceptionType forKey:kAVAExceptionType];
  [coder encodeObject:self.exceptionCode forKey:kAVAExceptionCode];
  [coder encodeObject:self.exceptionAddress forKey:kAVAExceptionAddress];
  [coder encodeObject:self.exceptionReason forKey:kAVAExceptionReason];
  [coder encodeObject:self.fatal forKey:kAVAFatal];
  [coder encodeObject:self.threads forKey:kAVAThreads];
  [coder encodeObject:self.exceptions forKey:kAVAExceptions];
  [coder encodeObject:self.binaries forKey:kAVABinaries];
}

@end
