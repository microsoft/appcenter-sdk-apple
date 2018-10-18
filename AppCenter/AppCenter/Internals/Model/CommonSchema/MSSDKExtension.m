#import "MSSDKExtension.h"
#import "MSCSModelConstants.h"

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
  if (self.installId) {
    dict[kMSSDKInstallId] = [self.installId UUIDString];
  }

  // The initial value corresponding to an epoch on a device should be 1, 0 means no seq attributes.
  if (self.seq) {
    dict[kMSSDKSeq] = @(self.seq);
  }
  return dict.count == 0 ? nil : dict;
}

#pragma mark - MSModel

- (BOOL)isValid {

  // All attributes are optional.
  return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSSDKExtension class]]) {
    return NO;
  }
  MSSDKExtension *sdkExt = (MSSDKExtension *)object;
  return ((!self.libVer && !sdkExt.libVer) || [self.libVer isEqualToString:sdkExt.libVer]) &&
         ((!self.epoch && !sdkExt.epoch) || [self.epoch isEqualToString:sdkExt.epoch]) && (self.seq == sdkExt.seq) &&
         ((!self.installId && !sdkExt.installId) || [self.installId isEqual:sdkExt.installId]);
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
