#import "MSACModelConstants.h"
#import "MSWrapperSdk.h"
#import "MSWrapperSdkInternal.h"

@implementation MSWrapperSdk

- (instancetype)initWithWrapperSdkVersion:(NSString *)wrapperSdkVersion
                           wrapperSdkName:(NSString *)wrapperSdkName
                    wrapperRuntimeVersion:(NSString *)wrapperRuntimeVersion
                   liveUpdateReleaseLabel:(NSString *)liveUpdateReleaseLabel
                  liveUpdateDeploymentKey:(NSString *)liveUpdateDeploymentKey
                    liveUpdatePackageHash:(NSString *)liveUpdatePackageHash {
  self = [super init];
  if (self) {
    _wrapperSdkVersion = wrapperSdkVersion;
    _wrapperSdkName = wrapperSdkName;
    _wrapperRuntimeVersion = wrapperRuntimeVersion;
    _liveUpdateReleaseLabel = liveUpdateReleaseLabel;
    _liveUpdateDeploymentKey = liveUpdateDeploymentKey;
    _liveUpdatePackageHash = liveUpdatePackageHash;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.wrapperSdkVersion) {
    dict[kMSWrapperSDKVersion] = self.wrapperSdkVersion;
  }
  if (self.wrapperSdkName) {
    dict[kMSWrapperSDKName] = self.wrapperSdkName;
  }
  if (self.wrapperRuntimeVersion) {
    dict[kMSWrapperRuntimeVersion] = self.wrapperRuntimeVersion;
  }
  if (self.liveUpdateReleaseLabel) {
    dict[kMSLiveUpdateReleaseLabel] = self.liveUpdateReleaseLabel;
  }
  if (self.liveUpdateDeploymentKey) {
    dict[kMSLiveUpdateDeploymentKey] = self.liveUpdateDeploymentKey;
  }
  if (self.liveUpdatePackageHash) {
    dict[kMSLiveUpdatePackageHash] = self.liveUpdatePackageHash;
  }
  return dict;
}

- (BOOL)isValid {
  return YES;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSWrapperSdk class]]) {
    return NO;
  }
  MSWrapperSdk *wrapperSdk = (MSWrapperSdk *)object;
  return ((!self.wrapperSdkVersion && !wrapperSdk.wrapperSdkVersion) ||
          [self.wrapperSdkVersion isEqualToString:wrapperSdk.wrapperSdkVersion]) &&
         ((!self.wrapperSdkName && !wrapperSdk.wrapperSdkName) || [self.wrapperSdkName isEqualToString:wrapperSdk.wrapperSdkName]) &&
         ((!self.wrapperRuntimeVersion && !wrapperSdk.wrapperRuntimeVersion) ||
          [self.wrapperRuntimeVersion isEqualToString:wrapperSdk.wrapperRuntimeVersion]) &&
         ((!self.liveUpdateReleaseLabel && !wrapperSdk.liveUpdateReleaseLabel) ||
          [self.liveUpdateReleaseLabel isEqualToString:wrapperSdk.liveUpdateReleaseLabel]) &&
         ((!self.liveUpdateDeploymentKey && !wrapperSdk.liveUpdateDeploymentKey) ||
          [self.liveUpdateDeploymentKey isEqualToString:wrapperSdk.liveUpdateDeploymentKey]) &&
         ((!self.liveUpdatePackageHash && !wrapperSdk.liveUpdatePackageHash) ||
          [self.liveUpdatePackageHash isEqualToString:wrapperSdk.liveUpdatePackageHash]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _wrapperSdkVersion = [coder decodeObjectForKey:kMSWrapperSDKVersion];
    _wrapperSdkName = [coder decodeObjectForKey:kMSWrapperSDKName];
    _wrapperRuntimeVersion = [coder decodeObjectForKey:kMSWrapperRuntimeVersion];
    _liveUpdateReleaseLabel = [coder decodeObjectForKey:kMSLiveUpdateReleaseLabel];
    _liveUpdateDeploymentKey = [coder decodeObjectForKey:kMSLiveUpdateDeploymentKey];
    _liveUpdatePackageHash = [coder decodeObjectForKey:kMSLiveUpdatePackageHash];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.wrapperSdkVersion forKey:kMSWrapperSDKVersion];
  [coder encodeObject:self.wrapperSdkName forKey:kMSWrapperSDKName];
  [coder encodeObject:self.wrapperRuntimeVersion forKey:kMSWrapperRuntimeVersion];
  [coder encodeObject:self.liveUpdateReleaseLabel forKey:kMSLiveUpdateReleaseLabel];
  [coder encodeObject:self.liveUpdateDeploymentKey forKey:kMSLiveUpdateDeploymentKey];
  [coder encodeObject:self.liveUpdatePackageHash forKey:kMSLiveUpdatePackageHash];
}

@end
