/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMBinary.h"

static NSString *const kSNMId = @"id";
static NSString *const kSNMStartAddress = @"start_address";
static NSString *const kSNMEndAddress = @"end_address";
static NSString *const kSNMName = @"name";
static NSString *const kSNMPath = @"path";
static NSString *const kSNMPrimaryArchitectureId = @"primary_architecture_id";
static NSString *const kSNMArchitectureVariantId = @"architecture_variant_id";

@implementation SNMBinary

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.binaryId) {
    dict[kSNMId] = self.binaryId;
  }
  if (self.startAddress) {
    dict[kSNMStartAddress] = self.startAddress;
  }
  if (self.endAddress) {
    dict[kSNMEndAddress] = self.endAddress;
  }
  if (self.name) {
    dict[kSNMName] = self.name;
  }
  if (self.path) {
    dict[kSNMPath] = self.path;
  }
  if (self.primaryArchitectureId) {
    dict[kSNMPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kSNMArchitectureVariantId] = self.architectureVariantId;
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _binaryId = [coder decodeObjectForKey:kSNMId];
    _startAddress = [coder decodeObjectForKey:kSNMStartAddress];
    _endAddress = [coder decodeObjectForKey:kSNMEndAddress];
    _name = [coder decodeObjectForKey:kSNMName];
    _path = [coder decodeObjectForKey:kSNMPath];
    _primaryArchitectureId = [coder decodeObjectForKey:kSNMPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kSNMArchitectureVariantId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.binaryId forKey:kSNMId];
  [coder encodeObject:self.startAddress forKey:kSNMStartAddress];
  [coder encodeObject:self.endAddress forKey:kSNMEndAddress];
  [coder encodeObject:self.name forKey:kSNMName];
  [coder encodeObject:self.path forKey:kSNMPath];
  [coder encodeObject:self.primaryArchitectureId forKey:kSNMPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kSNMArchitectureVariantId];
}

@end
