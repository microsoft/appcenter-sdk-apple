#import "MSSDKExtension.h"
#import "MSCSConstants.h"

@implementation MSSDKExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.libVer) {
    dict[kMSSDKLibVer] = self.libVer;
  }
  if (self.epoch) {
    dict[kMSSDKEpoch] = self.epoch;
  }
  dict[kMSSDKSeq] = @(self.seq);
  if (self.installId) {
    dict[kMSSDKInstallId] = self.installId;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.libVer && self.epoch && self.seq && self.installId;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSSDKExtension class]]) {
    return NO;
  }
  MSSDKExtension *sdkExt = (MSSDKExtension *)object;
  return ((!self.libVer && !sdkExt.libVer) || [self.libVer isEqualToString:sdkExt.libVer]) &&
         ((!self.epoch && !sdkExt.epoch) || [self.epoch isEqualToString:sdkExt.epoch]) && (self.seq == sdkExt.seq) &&
         ((!self.installId && !sdkExt.installId) || [self.installId isEqualToString:sdkExt.installId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _libVer = [coder decodeObjectForKey:kMSSDKLibVer];
    _epoch = [coder decodeObjectForKey:kMSSDKEpoch];
    _seq = [coder decodeInt64ForKey:kMSSDKSeq];
    _installId = [coder decodeObjectForKey:kMSSDKInstallId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.libVer forKey:kMSSDKLibVer];
  [coder encodeObject:self.epoch forKey:kMSSDKEpoch];
  [coder encodeInt64:self.seq forKey:kMSSDKSeq];
  [coder encodeObject:self.installId forKey:kMSSDKInstallId];
}

@end
