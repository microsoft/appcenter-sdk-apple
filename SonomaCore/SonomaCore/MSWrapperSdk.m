/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperSdk.h"
#import "MSWrapperSdkPrivate.h"

static NSString *const kSNMWrapperSdkVersion = @"wrapper_sdk_version";
static NSString *const kSNMWrapperSdkName = @"wrapper_sdk_name";
static NSString *const kSNMLiveUpdateReleaseLabel = @"live_update_release_label";
static NSString *const kSNMLiveUpdateDeploymentKey = @"live_update_deployment_key";
static NSString *const kSNMLiveUpdatePackageHash = @"live_update_package_hash";

@implementation MSWrapperSdk

- (instancetype) initWithWrapperSdkVersion:(NSString *)wrapperSdkVersion
                            wrapperSdkName:(NSString *)wrapperSdkName
                    liveUpdateReleaseLabel:(NSString *)liveUpdateReleaseLabel
                   liveUpdateDeploymentKey:(NSString *)liveUpdateDeploymentKey
                     liveUpdatePackageHash:(NSString *)liveUpdatePackageHash {
  self = [super init];
  if(self) {
    _wrapperSdkVersion = wrapperSdkVersion;
    _wrapperSdkName = wrapperSdkName;
    _liveUpdateReleaseLabel = liveUpdateReleaseLabel;
    _liveUpdateDeploymentKey = liveUpdateDeploymentKey;
    _liveUpdatePackageHash = liveUpdatePackageHash;
  }
  return self;
}


- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.wrapperSdkVersion) {
    dict[kSNMWrapperSdkVersion] = self.wrapperSdkVersion;
  }
  if (self.wrapperSdkName) {
    dict[kSNMWrapperSdkName] = self.wrapperSdkName;
  }
  if (self.liveUpdateReleaseLabel) {
    dict[kSNMLiveUpdateReleaseLabel] = self.liveUpdateReleaseLabel;
  }
  if (self.liveUpdateDeploymentKey) {
    dict[kSNMLiveUpdateDeploymentKey] = self.liveUpdateDeploymentKey;
  }
  if (self.liveUpdatePackageHash) {
    dict[kSNMLiveUpdatePackageHash] = self.liveUpdatePackageHash;
  }
  return dict;
}

- (BOOL)isEqual:(MSWrapperSdk *)wrapperSdk {

  if (!wrapperSdk)
    return NO;

  return ((!self.wrapperSdkVersion && !wrapperSdk.wrapperSdkVersion) ||
      [self.wrapperSdkVersion isEqualToString:wrapperSdk.wrapperSdkVersion]) &&
      ((!self.wrapperSdkName && !wrapperSdk.wrapperSdkName) ||
          [self.wrapperSdkName isEqualToString:wrapperSdk.wrapperSdkName]) &&
      ((!self.liveUpdateReleaseLabel && !wrapperSdk.liveUpdateReleaseLabel)
          || [self.liveUpdateReleaseLabel isEqualToString:wrapperSdk.liveUpdateReleaseLabel]) &&
      ((!self.liveUpdateDeploymentKey && !wrapperSdk.liveUpdateDeploymentKey)
          || [self.liveUpdateDeploymentKey isEqualToString:wrapperSdk.liveUpdateDeploymentKey]) &&
      ((!self.liveUpdatePackageHash && !wrapperSdk.liveUpdatePackageHash)
          || [self.liveUpdatePackageHash isEqualToString:wrapperSdk.liveUpdatePackageHash]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _wrapperSdkVersion = [coder decodeObjectForKey:kSNMWrapperSdkVersion];
    _wrapperSdkName = [coder decodeObjectForKey:kSNMWrapperSdkName];
    _liveUpdateReleaseLabel = [coder decodeObjectForKey:kSNMLiveUpdateReleaseLabel];
    _liveUpdateDeploymentKey = [coder decodeObjectForKey:kSNMLiveUpdateDeploymentKey];
    _liveUpdatePackageHash = [coder decodeObjectForKey:kSNMLiveUpdatePackageHash];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.wrapperSdkVersion forKey:kSNMWrapperSdkVersion];
  [coder encodeObject:self.wrapperSdkName forKey:kSNMWrapperSdkName];
  [coder encodeObject:self.liveUpdateReleaseLabel forKey:kSNMLiveUpdateReleaseLabel];
  [coder encodeObject:self.liveUpdateDeploymentKey forKey:kSNMLiveUpdateDeploymentKey];
  [coder encodeObject:self.liveUpdatePackageHash forKey:kSNMLiveUpdatePackageHash];
}

@end
