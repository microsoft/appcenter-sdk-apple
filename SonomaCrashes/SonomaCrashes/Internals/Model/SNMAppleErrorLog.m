/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAppleErrorLog.h"
#import "SNMBinary.h"
#import "SNMThread.h"

static NSString *const kSNMTypeError = @"apple_error";
static NSString *const kSNMPrimaryArchitectureId = @"primary_architecture_id";
static NSString *const kSNMArchitectureVariantId = @"architecture_variant_id";
static NSString *const kSNMApplicationPath = @"application_path";
static NSString *const kSNMOsExceptionType = @"os_exception_type";
static NSString *const kSNMOsExceptionCode = @"os_exception_code";
static NSString *const kSNMOsExceptionAddress = @"os_exception_address";
static NSString *const kSNMExceptionType = @"exception_type";
static NSString *const kSNMExceptionReason = @"exception_reason";
static NSString *const kSNMThreads = @"threads";
static NSString *const kSNMBinaries = @"binaries";
static NSString *const kSNMRegisters = @"registers";

@implementation SNMAppleErrorLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kSNMTypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.primaryArchitectureId) {
    dict[kSNMPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kSNMArchitectureVariantId] = self.architectureVariantId;
  }
  if (self.applicationPath) {
    dict[kSNMApplicationPath] = self.applicationPath;
  }
  if (self.osExceptionType) {
    dict[kSNMOsExceptionType] = self.osExceptionType;
  }
  if (self.osExceptionCode) {
    dict[kSNMOsExceptionCode] = self.osExceptionCode;
  }
  if (self.osExceptionAddress) {
    dict[kSNMOsExceptionAddress] = self.osExceptionAddress;
  }
  if (self.exceptionType) {
    dict[kSNMExceptionType] = self.exceptionType;
  }
  if (self.exceptionReason) {
    dict[kSNMExceptionReason] = self.exceptionReason;
  }
  if (self.threads) {
    NSMutableArray *threadsArray = [NSMutableArray array];
    for (SNMThread *thread in self.threads) {
      [threadsArray addObject:[thread serializeToDictionary]];
    }
    dict[kSNMThreads] = threadsArray;
  }
  if (self.binaries) {
    NSMutableArray *binariesArray = [NSMutableArray array];
    for (SNMBinary *binary in self.binaries) {
      [binariesArray addObject:[binary serializeToDictionary]];
    }
    dict[kSNMBinaries] = binariesArray;
  }
  if (self.registers) {
    dict[kSNMRegisters] = self.registers;
  }

  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.primaryArchitectureId && self.applicationPath && self.osExceptionType &&
         self.osExceptionCode && self.osExceptionAddress;
}

- (BOOL)isEqual:(SNMAppleErrorLog *)errorLog {
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
    _primaryArchitectureId = [coder decodeObjectForKey:kSNMPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kSNMArchitectureVariantId];
    _applicationPath = [coder decodeObjectForKey:kSNMApplicationPath];
    _osExceptionType = [coder decodeObjectForKey:kSNMOsExceptionType];
    _osExceptionCode = [coder decodeObjectForKey:kSNMOsExceptionCode];
    _osExceptionAddress = [coder decodeObjectForKey:kSNMOsExceptionAddress];
    _exceptionType = [coder decodeObjectForKey:kSNMExceptionType];
    _exceptionReason = [coder decodeObjectForKey:kSNMExceptionReason];
    _threads = [coder decodeObjectForKey:kSNMThreads];
    _binaries = [coder decodeObjectForKey:kSNMBinaries];
    _registers = [coder decodeObjectForKey:kSNMRegisters];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.primaryArchitectureId forKey:kSNMPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kSNMArchitectureVariantId];
  [coder encodeObject:self.applicationPath forKey:kSNMApplicationPath];
  [coder encodeObject:self.osExceptionType forKey:kSNMOsExceptionType];
  [coder encodeObject:self.osExceptionCode forKey:kSNMOsExceptionCode];
  [coder encodeObject:self.osExceptionAddress forKey:kSNMOsExceptionAddress];
  [coder encodeObject:self.exceptionType forKey:kSNMExceptionType];
  [coder encodeObject:self.exceptionReason forKey:kSNMExceptionReason];
  [coder encodeObject:self.threads forKey:kSNMThreads];
  [coder encodeObject:self.binaries forKey:kSNMBinaries];
  [coder encodeObject:self.registers forKey:kSNMRegisters];
}

@end
