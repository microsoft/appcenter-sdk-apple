#import "MSBinary.h"

static NSString *const kMSId = @"id";
static NSString *const kMSStartAddress = @"startAddress";
static NSString *const kMSEndAddress = @"endAddress";
static NSString *const kMSName = @"name";
static NSString *const kMSPath = @"path";
static NSString *const kMSArchitecture = @"architecture";
static NSString *const kMSPrimaryArchitectureId = @"primaryArchitectureId";
static NSString *const kMSArchitectureVariantId = @"architectureVariantId";

@implementation MSBinary

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.binaryId) {
    dict[kMSId] = self.binaryId;
  }
  if (self.startAddress) {
    dict[kMSStartAddress] = self.startAddress;
  }
  if (self.endAddress) {
    dict[kMSEndAddress] = self.endAddress;
  }
  if (self.name) {
    dict[kMSName] = self.name;
  }
  if (self.path) {
    dict[kMSPath] = self.path;
  }
  if (self.architecture) {
    dict[kMSArchitecture] = self.architecture;
  }
  if (self.primaryArchitectureId) {
    dict[kMSPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kMSArchitectureVariantId] = self.architectureVariantId;
  }

  return dict;
}

- (BOOL)isValid {
  return self.binaryId && self.startAddress && self.endAddress && self.name && self.path;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSBinary class]]) {
    return NO;
  }
  MSBinary *binary = (MSBinary *)object;
  return ((!self.binaryId && !binary.binaryId) || [self.binaryId isEqualToString:binary.binaryId]) &&
         ((!self.startAddress && !binary.startAddress) || [self.startAddress isEqualToString:binary.startAddress]) &&
         ((!self.endAddress && !binary.endAddress) || [self.endAddress isEqualToString:binary.endAddress]) &&
         ((!self.name && !binary.name) || [self.name isEqualToString:binary.name]) &&
         ((!self.path && !binary.path) || [self.path isEqualToString:binary.path]) &&
         ((!self.architecture && !binary.architecture) || [self.architecture isEqualToString:binary.architecture]) &&
         ((!self.primaryArchitectureId && !binary.primaryArchitectureId) ||
          [self.primaryArchitectureId isEqual:binary.primaryArchitectureId]) &&
         ((!self.architectureVariantId && !binary.architectureVariantId) ||
          [self.architectureVariantId isEqual:binary.architectureVariantId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _binaryId = [coder decodeObjectForKey:kMSId];
    _startAddress = [coder decodeObjectForKey:kMSStartAddress];
    _endAddress = [coder decodeObjectForKey:kMSEndAddress];
    _name = [coder decodeObjectForKey:kMSName];
    _path = [coder decodeObjectForKey:kMSPath];
    _architecture = [coder decodeObjectForKey:kMSArchitecture];
    _primaryArchitectureId = [coder decodeObjectForKey:kMSPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kMSArchitectureVariantId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.binaryId forKey:kMSId];
  [coder encodeObject:self.startAddress forKey:kMSStartAddress];
  [coder encodeObject:self.endAddress forKey:kMSEndAddress];
  [coder encodeObject:self.name forKey:kMSName];
  [coder encodeObject:self.path forKey:kMSPath];
  [coder encodeObject:self.architecture forKey:kMSArchitecture];
  [coder encodeObject:self.primaryArchitectureId forKey:kMSPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kMSArchitectureVariantId];
}

@end
