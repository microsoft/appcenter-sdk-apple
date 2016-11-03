/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAppleErrorLog.h"
#import "MSBinary.h"
#import "MSThread.h"

static NSString *const kMSTypeError = @"apple_error";
static NSString *const kMSPrimaryArchitectureId = @"primary_architecture_id";
static NSString *const kMSArchitectureVariantId = @"architecture_variant_id";
static NSString *const kMSApplicationPath = @"application_path";
static NSString *const kMSOsExceptionType = @"os_exception_type";
static NSString *const kMSOsExceptionCode = @"os_exception_code";
static NSString *const kMSOsExceptionAddress = @"os_exception_address";
static NSString *const kMSExceptionType = @"exception_type";
static NSString *const kMSExceptionReason = @"exception_reason";
static NSString *const kMSThreads = @"threads";
static NSString *const kMSBinaries = @"binaries";
static NSString *const kMSRegisters = @"registers";

@implementation MSAppleErrorLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kMSTypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.primaryArchitectureId) {
    dict[kMSPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kMSArchitectureVariantId] = self.architectureVariantId;
  }
  if (self.applicationPath) {
    dict[kMSApplicationPath] = self.applicationPath;
  }
  if (self.osExceptionType) {
    dict[kMSOsExceptionType] = self.osExceptionType;
  }
  if (self.osExceptionCode) {
    dict[kMSOsExceptionCode] = self.osExceptionCode;
  }
  if (self.osExceptionAddress) {
    dict[kMSOsExceptionAddress] = self.osExceptionAddress;
  }
  if (self.exceptionType) {
    dict[kMSExceptionType] = self.exceptionType;
  }
  if (self.exceptionReason) {
    dict[kMSExceptionReason] = self.exceptionReason;
  }
  if (self.threads) {
    NSMutableArray *threadsArray = [NSMutableArray array];
    for (MSThread *thread in self.threads) {
      [threadsArray addObject:[thread serializeToDictionary]];
    }
    dict[kMSThreads] = threadsArray;
  }
  if (self.binaries) {
    NSMutableArray *binariesArray = [NSMutableArray array];
    for (MSBinary *binary in self.binaries) {
      [binariesArray addObject:[binary serializeToDictionary]];
    }
    dict[kMSBinaries] = binariesArray;
  }
  if (self.registers) {
    dict[kMSRegisters] = self.registers;
  }

  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.primaryArchitectureId && self.applicationPath && self.osExceptionType &&
         self.osExceptionCode && self.osExceptionAddress;
}

- (BOOL)isEqual:(MSAppleErrorLog *)errorLog {
  if (!errorLog)
    return NO;

  return ((!self.primaryArchitectureId && !errorLog.primaryArchitectureId) ||
          [self.primaryArchitectureId isEqual:errorLog.primaryArchitectureId]) &&
         ((!self.architectureVariantId && !errorLog.architectureVariantId) ||
          [self.architectureVariantId isEqual:errorLog.architectureVariantId]) &&
         ((!self.applicationPath && !errorLog.applicationPath) ||
          [self.applicationPath isEqualToString:errorLog.applicationPath]) &&
         ((!self.osExceptionType && !errorLog.osExceptionType) ||
          [self.osExceptionType isEqualToString:errorLog.osExceptionType]) &&
         ((!self.osExceptionCode && !errorLog.osExceptionCode) ||
          [self.osExceptionCode isEqualToString:errorLog.osExceptionCode]) &&
         ((!self.osExceptionAddress && !errorLog.osExceptionAddress) ||
          [self.osExceptionAddress isEqualToString:errorLog.osExceptionAddress]) &&
         ((!self.exceptionType && !errorLog.exceptionType) ||
          [self.exceptionType isEqualToString:errorLog.exceptionType]) &&
         ((!self.exceptionReason && !errorLog.exceptionReason) ||
          [self.exceptionReason isEqualToString:errorLog.exceptionReason]) &&
         ((!self.threads && !errorLog.threads) || [self.threads isEqualToArray:errorLog.threads]) &&
         ((!self.binaries && !errorLog.binaries) || [self.binaries isEqualToArray:errorLog.binaries]) &&
         ((!self.registers && !errorLog.registers) || [self.registers isEqualToDictionary:errorLog.registers]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _primaryArchitectureId = [coder decodeObjectForKey:kMSPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kMSArchitectureVariantId];
    _applicationPath = [coder decodeObjectForKey:kMSApplicationPath];
    _osExceptionType = [coder decodeObjectForKey:kMSOsExceptionType];
    _osExceptionCode = [coder decodeObjectForKey:kMSOsExceptionCode];
    _osExceptionAddress = [coder decodeObjectForKey:kMSOsExceptionAddress];
    _exceptionType = [coder decodeObjectForKey:kMSExceptionType];
    _exceptionReason = [coder decodeObjectForKey:kMSExceptionReason];
    _threads = [coder decodeObjectForKey:kMSThreads];
    _binaries = [coder decodeObjectForKey:kMSBinaries];
    _registers = [coder decodeObjectForKey:kMSRegisters];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.primaryArchitectureId forKey:kMSPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kMSArchitectureVariantId];
  [coder encodeObject:self.applicationPath forKey:kMSApplicationPath];
  [coder encodeObject:self.osExceptionType forKey:kMSOsExceptionType];
  [coder encodeObject:self.osExceptionCode forKey:kMSOsExceptionCode];
  [coder encodeObject:self.osExceptionAddress forKey:kMSOsExceptionAddress];
  [coder encodeObject:self.exceptionType forKey:kMSExceptionType];
  [coder encodeObject:self.exceptionReason forKey:kMSExceptionReason];
  [coder encodeObject:self.threads forKey:kMSThreads];
  [coder encodeObject:self.binaries forKey:kMSBinaries];
  [coder encodeObject:self.registers forKey:kMSRegisters];
}

@end
