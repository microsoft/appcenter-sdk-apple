/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVABinary.h"

static NSString *const kAVAId = @"id";
static NSString *const kAVAStartAddress = @"startAddress";
static NSString *const kAVAEndAddress = @"endAddress";
static NSString *const kAVAName = @"name";
static NSString *const kAVAArchitecture = @"architecture";
static NSString *const kAVAPath = @"path";

@implementation AVABinary

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
  if (self.architecture) {
    dict[kAVAArchitecture] = self.architecture;
  }
  if (self.path) {
    dict[kAVAPath] = self.path;
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
    _architecture = [coder decodeObjectForKey:kAVAArchitecture];
    _path = [coder decodeObjectForKey:kAVAPath];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.binaryId forKey:kAVAId];
  [coder encodeObject:self.startAddress forKey:kAVAStartAddress];
  [coder encodeObject:self.endAddress forKey:kAVAEndAddress];
  [coder encodeObject:self.name forKey:kAVAName];
  [coder encodeObject:self.architecture forKey:kAVAArchitecture];
  [coder encodeObject:self.path forKey:kAVAPath];
}

@end
