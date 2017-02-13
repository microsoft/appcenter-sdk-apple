/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSReleaseDetails.h"
#import "MSDistributionGroup.h"

static NSString *const kMSId = @"id";
static NSString *const kMSStatus = @"status";
static NSString *const kMSAppName = @"app_name";
static NSString *const kMSVersion = @"version";
static NSString *const kMSShortVersion = @"short_version";
static NSString *const kMSReleaseNotes = @"release_notes";
static NSString *const kMSProvisioningProfileName = @"provisioning_profile_name";
static NSString *const kMSSize = @"size";
static NSString *const kMSMinOs = @"min_os";
static NSString *const kMSFingerprint = @"fingerprint";
static NSString *const kMSUploadedAt = @"uploaded_at";
static NSString *const kMSDownloadUrl = @"download_url";
static NSString *const kMSAppIconUrl = @"app_icon_url";
static NSString *const kMSInstallUrl = @"install_url";
static NSString *const kMSDistributionGroups = @"distribution_groups";

@implementation MSReleaseDetails

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary {
  if ((self = [super init])) {
    if (dictionary[kMSId]) {
      self.id = dictionary[kMSId];
    }
    if (dictionary[kMSStatus]) {
      self.status = dictionary[kMSStatus];
    }
    if (dictionary[kMSAppName]) {
      self.appName = dictionary[kMSAppName];
    }
    if (dictionary[kMSVersion]) {
      self.version = dictionary[kMSVersion];
    }
    if (dictionary[kMSShortVersion]) {
      self.shortVersion = dictionary[kMSShortVersion];
    }
    if (dictionary[kMSReleaseNotes]) {
      self.releaseNotes = dictionary[kMSReleaseNotes];
    }
    if (dictionary[kMSProvisioningProfileName]) {
      self.provisioningProfileName = dictionary[kMSProvisioningProfileName];
    }
    if (dictionary[kMSSize]) {
      self.size = dictionary[kMSSize];
    }
    if (dictionary[kMSMinOs]) {
      self.minOs = dictionary[kMSMinOs];
    }
    if (dictionary[kMSFingerprint]) {
      self.fingerprint = dictionary[kMSFingerprint];
    }
    if (dictionary[kMSUploadedAt]) {
      self.uploadedAt = dictionary[kMSUploadedAt];
    }
    if (dictionary[kMSDownloadUrl]) {
      self.downloadUrl = dictionary[kMSDownloadUrl];
    }
    if (dictionary[kMSAppIconUrl]) {
      self.appIconUrl = dictionary[kMSAppIconUrl];
    }
    if (dictionary[kMSInstallUrl]) {
      self.installUrl = dictionary[kMSInstallUrl];
    }
    if (dictionary[kMSDistributionGroups]) {
      // TODO: Implement here. There is no spec for DistributionGroup data model.
    }
  }
  return self;
}

@end
