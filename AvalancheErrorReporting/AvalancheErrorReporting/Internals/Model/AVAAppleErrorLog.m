/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAppleErrorLog.h"
#import "AVAThread.h"
#import "AVABinary.h"

static NSString *const kAVATypeError = @"error";
static NSString *const kAVAPrimaryArchitectureId = @"primaryArchitectureId";
static NSString *const kAVAArchitectureVariantId = @"architectureVariantId";
static NSString *const kAVAApplicationPath = @"applicationPath";
static NSString *const kAVAOsExceptionType = @"osExceptionType";
static NSString *const kAVAOsExceptionCode = @"osExceptionCode";
static NSString *const kAVAOsExceptionAddress = @"osExceptionAddress";
static NSString *const kAVAExceptionType = @"exceptionType";
static NSString *const kAVAExceptionReason = @"exceptionReason";
static NSString *const kAVAThreads = @"threads";
static NSString *const kAVABinaries = @"binaries";
static NSString *const kAVARegisters = @"registers";


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
  
  if (self.primaryArchitectureId) {
    dict[kAVAPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kAVAArchitectureVariantId] = self.architectureVariantId;
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
  if (self.threads) {
    NSMutableArray *threadsArray = [NSMutableArray array];
    for (AVAThread *thread in self.threads) {
      [threadsArray addObject:[thread serializeToDictionary]];
    }
    dict[kAVAThreads] = threadsArray;
  }
  if (self.binaries) {
    NSMutableArray *binariesArray = [NSMutableArray array];
    for (AVABinary *binary in self.binaries) {
      [binariesArray addObject:[binary serializeToDictionary]];
    }
    dict[kAVABinaries] = binariesArray;
  }
  if (self.registers) {
    dict[kAVARegisters] = self.registers;
  }
  
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kAVAType];
    _primaryArchitectureId = [coder decodeObjectForKey:kAVAPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kAVAArchitectureVariantId];
    _applicationPath = [coder decodeObjectForKey:kAVAApplicationPath];
    _osExceptionType = [coder decodeObjectForKey:kAVAOsExceptionType];
    _osExceptionCode = [coder decodeObjectForKey:kAVAOsExceptionCode];
    _osExceptionAddress = [coder decodeObjectForKey:kAVAOsExceptionAddress];
    _exceptionType = [coder decodeObjectForKey:kAVAExceptionType];
    _exceptionReason = [coder decodeObjectForKey:kAVAExceptionReason];
    _threads = [coder decodeObjectForKey:kAVAThreads];
    _binaries = [coder decodeObjectForKey:kAVABinaries];
    _registers = [coder decodeObjectForKey:kAVARegisters];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.primaryArchitectureId forKey:kAVAPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kAVAArchitectureVariantId];
  [coder encodeObject:self.applicationPath forKey:kAVAApplicationPath];
  [coder encodeObject:self.osExceptionType forKey:kAVAOsExceptionType];
  [coder encodeObject:self.osExceptionCode forKey:kAVAOsExceptionCode];
  [coder encodeObject:self.osExceptionAddress forKey:kAVAOsExceptionAddress];
  [coder encodeObject:self.exceptionType forKey:kAVAExceptionType];
  [coder encodeObject:self.exceptionReason forKey:kAVAExceptionReason];
  [coder encodeObject:self.threads forKey:kAVAThreads];
  [coder encodeObject:self.binaries forKey:kAVABinaries];
  [coder encodeObject:self.registers forKey:kAVARegisters];
}

@end
