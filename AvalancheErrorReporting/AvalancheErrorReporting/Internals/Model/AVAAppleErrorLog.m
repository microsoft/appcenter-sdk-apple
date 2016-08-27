/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAppleErrorLog.h"
#import "AVAAppleThread.h"

static NSString *const kAVATypeError = @"error";

static NSString *const kAVAErrorId = @"id";
static NSString *const kAVAProcessId = @"processId";
static NSString *const kAVAProcessName = @"processName";
static NSString *const kAVAParentProcessId = @"parentProcessId";
static NSString *const kAVAParentProcessName = @"parentProcessName";
static NSString *const kAVAErrorThreadId = @"errorThreadId";
static NSString *const kAVAErrorThreadName = @"errorThreadName";
static NSString *const kAVAFatal = @"fatal";
static NSString *const kAVAAppLaunchTOffset = @"appLaunchTOffset";
static NSString *const kAVACpuType = @"cpuType";
static NSString *const kAVACpuSubType = @"cpuSubType";
static NSString *const kAVAApplicationPath = @"applicationPath";
static NSString *const kAVAOsExceptionType = @"osExceptionType";
static NSString *const kAVAOsExceptionCode = @"osExceptionCode";
static NSString *const kAVAOsExceptionAddress = @"osExceptionAddress";
static NSString *const kAVAExceptionType = @"exceptionType";
static NSString *const kAVAExceptionReason = @"exceptionReason";
static NSString *const kAVARegisters = @"registers";
static NSString *const kAVAThreads = @"threads";
static NSString *const kAVABinaries = @"binaries";

@implementation AVAAppleErrorLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kAVATypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

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
  if (self.errorThreadId) {
    dict[kAVAErrorThreadId] = self.errorThreadId;
  }
  if (self.errorThreadName) {
    dict[kAVAErrorThreadName] = self.errorThreadName;
  }
  dict[kAVAFatal] = self.fatal?  @YES : @NO ;
  if (self.appLaunchTOffset) {
    dict[kAVAAppLaunchTOffset] = self.appLaunchTOffset;
  }
  if (self.cpuType) {
    dict[kAVACpuType] = self.cpuType;
  }
  if (self.cpuSubType) {
    dict[kAVACpuSubType] = self.cpuSubType;
  }
  if (self.applicationPath) {
    dict[kAVAApplicationPath] = self.applicationPath;
  }
  if (self.osExceptionType) {
    dict[kAVAOsExceptionType] = self.osExceptionType;
  }
  if (self.osExceptionCode) {
    dict[kAVAOsExceptionCode] = self.osExceptionCode;
  }
  if (self.osExceptionAddress) {
    dict[kAVAOsExceptionAddress] = self.osExceptionAddress;
  }
  if (self.exceptionType) {
    dict[kAVAExceptionType] = self.exceptionType;
  }
  if (self.exceptionReason) {
    dict[kAVAExceptionReason] = self.exceptionReason;
  }
  if (self.registers) {
    dict[kAVARegisters] = self.registers;
  }
  if (self.threads) {
    NSMutableArray *threadsArray = [NSMutableArray array];
    for (AVAAppleThread *thread in self.threads) {
      [threadsArray addObject:[thread serializeToDictionary]];
    }
    dict[kAVAThreads] = threadsArray;
  }
  if (self.binaries) {
    NSMutableArray *binariesArray = [NSMutableArray array];
    for (AVAAppleThread *binary in self.threads) {
      [binariesArray addObject:[binary serializeToDictionary]];
    }
    dict[kAVABinaries] = binariesArray;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kAVAType];
    _errorId = [coder decodeObjectForKey:kAVAErrorId];
    _processId = [coder decodeObjectForKey:kAVAProcessId];
    _processName = [coder decodeObjectForKey:kAVAProcessName];
    _parentProcessId = [coder decodeObjectForKey:kAVAParentProcessId];
    _parentProcessName = [coder decodeObjectForKey:kAVAParentProcessName];
    _errorThreadId = [coder decodeObjectForKey:kAVAErrorThreadId];
    _errorThreadName = [coder decodeObjectForKey:kAVAErrorThreadName];
    _fatal = [coder decodeBoolForKey:kAVAFatal];
    _appLaunchTOffset = [coder decodeObjectForKey:kAVAAppLaunchTOffset];
    _cpuType = [coder decodeObjectForKey:kAVACpuType];
    _cpuSubType = [coder decodeObjectForKey:kAVACpuSubType];
    _applicationPath = [coder decodeObjectForKey:kAVAApplicationPath];
    _osExceptionType = [coder decodeObjectForKey:kAVAOsExceptionType];
    _osExceptionCode = [coder decodeObjectForKey:kAVAOsExceptionCode];
    _osExceptionAddress = [coder decodeObjectForKey:kAVAOsExceptionAddress];
    _exceptionType = [coder decodeObjectForKey:kAVAExceptionType];
    _exceptionReason = [coder decodeObjectForKey:kAVAExceptionReason];
    _registers = [coder decodeObjectForKey:kAVARegisters];
    _threads = [coder decodeObjectForKey:kAVAThreads];
    _binaries = [coder decodeObjectForKey:kAVABinaries];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.errorId forKey:kAVAErrorId];
  [coder encodeObject:self.processId forKey:kAVAProcessId];
  [coder encodeObject:self.processName forKey:kAVAProcessName];
  [coder encodeObject:self.parentProcessId forKey:kAVAParentProcessId];
  [coder encodeObject:self.parentProcessName forKey:kAVAParentProcessName];
  [coder encodeObject:self.errorThreadId forKey:kAVAErrorThreadId];
  [coder encodeObject:self.errorThreadName forKey:kAVAErrorThreadName];
  [coder encodeBool:self.fatal forKey:kAVAFatal];
  [coder encodeObject:self.appLaunchTOffset forKey:kAVAAppLaunchTOffset];
  [coder encodeObject:self.cpuType forKey:kAVACpuType];
  [coder encodeObject:self.cpuSubType forKey:kAVACpuSubType];
  [coder encodeObject:self.applicationPath forKey:kAVAApplicationPath];
  [coder encodeObject:self.osExceptionType forKey:kAVAOsExceptionType];
  [coder encodeObject:self.osExceptionCode forKey:kAVAOsExceptionCode];
  [coder encodeObject:self.osExceptionAddress forKey:kAVAOsExceptionAddress];
  [coder encodeObject:self.exceptionType forKey:kAVAExceptionType];
  [coder encodeObject:self.exceptionReason forKey:kAVAExceptionReason];
  [coder encodeObject:self.registers forKey:kAVARegisters];
  [coder encodeObject:self.threads forKey:kAVAThreads];
  [coder encodeObject:self.binaries forKey:kAVABinaries];
}

@end
