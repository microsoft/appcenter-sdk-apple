/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAppleBinary.h"

static NSString *const kAVAId = @"id";
static NSString *const kAVAStartAddress = @"startAddress";
static NSString *const kAVAEndAddress = @"endAddress";
static NSString *const kAVAName = @"name";
static NSString *const kAVAPath = @"path";
static NSString *const kAVACpuType = @"cpuType";
static NSString *const kAVACpuSubType = @"cpuSubType";


@implementation AVAAppleBinary

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.binaryId) {
    dict[kAVAId] = self.binaryId;
  }
  if (self.startAddress) {
    dict[kAVAStartAddress] = self.startAddress;
  }
  if (self.endAddress) {
    dict[kAVAEndAddress] = self.endAddress;
  }
  if (self.name) {
    dict[kAVAName] = self.name;
  }
  if (self.path) {
    dict[kAVAPath] = self.path;
  }
  if (self.cpuType) {
    dict[kAVACpuType] = self.cpuType;
  }
  if (self.cpuSubType) {
    dict[kAVACpuSubType] = self.cpuSubType;
  }
  
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _binaryId = [coder decodeObjectForKey:kAVAId];
    _startAddress = [coder decodeObjectForKey:kAVAStartAddress];
    _endAddress = [coder decodeObjectForKey:kAVAEndAddress];
    _name = [coder decodeObjectForKey:kAVAName];
    _path = [coder decodeObjectForKey:kAVAPath];
    _cpuType = [coder decodeObjectForKey:kAVACpuType];
    _cpuSubType = [coder decodeObjectForKey:kAVACpuSubType];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.binaryId forKey:kAVAId];
  [coder encodeObject:self.startAddress forKey:kAVAStartAddress];
  [coder encodeObject:self.endAddress forKey:kAVAEndAddress];
  [coder encodeObject:self.name forKey:kAVAName];
  [coder encodeObject:self.path forKey:kAVAPath];
  [coder encodeObject:self.cpuType forKey:kAVACpuType];
  [coder encodeObject:self.cpuSubType forKey:kAVACpuSubType];
}

@end
