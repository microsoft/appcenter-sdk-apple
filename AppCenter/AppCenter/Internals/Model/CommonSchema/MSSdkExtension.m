#import "MSSdkExtension.h"

static NSString *const kMSSdkLibVer = @"libVer";
static NSString *const kMSSdkEpoch = @"epoch";
static NSString *const kMSSdkSeq = @"seq";
static NSString *const kMSSdkInstallId = @"installId";

@implementation MSSdkExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.libVer) {
    dict[kMSSdkLibVer] = self.libVer;
  }
  if (self.epoch) {
    dict[kMSSdkEpoch] = self.epoch;
  }
  dict[kMSSdkSeq] = @(self.seq);
  if (self.installId) {
    dict[kMSSdkInstallId] = self.installId;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.libVer && self.epoch && self.seq && self.installId;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSSdkExtension class]]) {
    return NO;
  }
  MSSdkExtension *sdkExt = (MSSdkExtension *)object;
  return ((!self.libVer && !sdkExt.libVer) || [self.libVer isEqualToString:sdkExt.libVer]) &&
         ((!self.epoch && !sdkExt.epoch) || [self.epoch isEqualToString:sdkExt.epoch]) && (self.seq == sdkExt.seq) &&
         ((!self.installId && !sdkExt.installId) || [self.installId isEqualToString:sdkExt.installId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _libVer = [coder decodeObjectForKey:kMSSdkLibVer];
    _epoch = [coder decodeObjectForKey:kMSSdkEpoch];
    _seq = [coder decodeObjectForKey:kMSSdkSeq];
    _installId = [coder decodeObjectForKey:kMSSdkInstallId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.libVer forKey:kMSSdkLibVer];
  [coder encodeObject:self.epoch forKey:kMSSdkEpoch];
  [coder encodeInt64:self.seq forKey:kMSSdkSeq];
  [coder encodeObject:self.installId forKey:kMSSdkInstallId];
}

@end
