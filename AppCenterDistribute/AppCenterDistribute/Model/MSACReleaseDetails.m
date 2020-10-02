// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAbstractLogInternal.h"
#import "MSACDistributionGroup.h"
#import "MSACReleaseDetailsPrivate.h"
#import "MSACUtility+Date.h"

static NSString *const kMSACId = @"id";
static NSString *const kMSACStatus = @"status";
static NSString *const kMSACAppName = @"app_name";
static NSString *const kMSACVersion = @"version";
static NSString *const kMSACShortVersion = @"short_version";
static NSString *const kMSACReleaseNotes = @"release_notes";
static NSString *const kMSACProvisioningProfileName = @"provisioning_profile_name";
static NSString *const kMSACSize = @"size";
static NSString *const kMSACMinOs = @"min_os";
static NSString *const kMSACMandatoryUpdate = @"mandatory_update";
static NSString *const kMSACFingerprint = @"fingerprint";
static NSString *const kMSACUploadedAt = @"uploaded_at";
static NSString *const kMSACDownloadUrl = @"download_url";
static NSString *const kMSACAppIconUrl = @"app_icon_url";
static NSString *const kMSACInstallUrl = @"install_url";
static NSString *const kMSACReleaseNotesUrl = @"release_notes_url";
static NSString *const kMSACDistributionGroupId = @"distribution_group_id";
static NSString *const kMSACDistributionGroups = @"distribution_groups";
static NSString *const kMSACPackageHashes = @"package_hashes";

@implementation MSACReleaseDetails

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSACId]) {
      self.id = dictionary[kMSACId];
    }
    if (dictionary[kMSACStatus]) {
      self.status = dictionary[kMSACStatus];
    }
    if (dictionary[kMSACAppName]) {
      self.appName = dictionary[kMSACAppName];
    }
    if (dictionary[kMSACVersion]) {
      self.version = dictionary[kMSACVersion];
    }
    if (dictionary[kMSACShortVersion]) {
      self.shortVersion = dictionary[kMSACShortVersion];
    }
    if (dictionary[kMSACReleaseNotes]) {
      if ([(NSObject *)dictionary[kMSACReleaseNotes] isKindOfClass:[NSNull class]]) {
        self.releaseNotes = nil;
      } else {
        self.releaseNotes = dictionary[kMSACReleaseNotes];
      }
    }
    if (dictionary[kMSACProvisioningProfileName]) {
      self.provisioningProfileName = dictionary[kMSACProvisioningProfileName];
    }
    if (dictionary[kMSACSize]) {
      self.size = dictionary[kMSACSize];
    }
    if (dictionary[kMSACMinOs]) {
      self.minOs = dictionary[kMSACMinOs];
    }
    if (dictionary[kMSACMandatoryUpdate]) {
      self.mandatoryUpdate = [(NSObject *)dictionary[kMSACMandatoryUpdate] isEqual:@YES] ? YES : NO;
    }
    if (dictionary[kMSACFingerprint]) {
      self.fingerprint = dictionary[kMSACFingerprint];
    }
    if (dictionary[kMSACUploadedAt]) {
      NSString *_Nonnull uploadedAt = (NSString * _Nonnull) dictionary[kMSACUploadedAt];
      self.uploadedAt = [MSACUtility dateFromISO8601:uploadedAt];
    }
    if (dictionary[kMSACDownloadUrl]) {
      if ([(NSObject *)dictionary[kMSACDownloadUrl] isKindOfClass:[NSNull class]]) {
        self.downloadUrl = nil;
      } else {
        NSString *_Nonnull downloadUrl = (NSString * _Nonnull) dictionary[kMSACDownloadUrl];
        self.downloadUrl = [NSURL URLWithString:downloadUrl];
      }
    }
    if (dictionary[kMSACAppIconUrl]) {
      if ([(NSObject *)dictionary[kMSACAppIconUrl] isKindOfClass:[NSNull class]]) {
        self.appIconUrl = nil;
      } else {
        NSString *_Nonnull appIconUrl = (NSString * _Nonnull) dictionary[kMSACAppIconUrl];
        self.appIconUrl = [NSURL URLWithString:appIconUrl];
      }
    }
    if (dictionary[kMSACInstallUrl]) {
      if ([(NSObject *)dictionary[kMSACInstallUrl] isKindOfClass:[NSNull class]]) {
        self.installUrl = nil;
      } else {
        NSString *_Nonnull installUrl = (NSString * _Nonnull) dictionary[kMSACInstallUrl];
        self.installUrl = [NSURL URLWithString:installUrl];
      }
    }
    if (dictionary[kMSACReleaseNotesUrl]) {
      if ([(NSObject *)dictionary[kMSACReleaseNotesUrl] isKindOfClass:[NSNull class]]) {
        self.releaseNotesUrl = nil;
      } else {
        NSString *_Nonnull releaseNotesUrl = (NSString * _Nonnull) dictionary[kMSACReleaseNotesUrl];
        self.releaseNotesUrl = [NSURL URLWithString:releaseNotesUrl];
      }
    }
    if (dictionary[kMSACDistributionGroupId]) {
      self.distributionGroupId = dictionary[kMSACDistributionGroupId];
    }
    if (dictionary[kMSACDistributionGroups]) {

      // TODO: DistributionGroup has no properties so skip it until it has properties.
    }
    if (dictionary[kMSACPackageHashes]) {
      self.packageHashes = dictionary[kMSACPackageHashes];
    }
  }
  return self;
}

- (NSDictionary *)serializeToDictionary {
  NSMutableDictionary *dictionary = [NSMutableDictionary new];

  // Fill in the dictionary with properties.
  if (self.id) {
    dictionary[kMSACId] = self.id;
  }
  if (self.status) {
    dictionary[kMSACStatus] = self.status;
  }
  if (self.appName) {
    dictionary[kMSACAppName] = self.appName;
  }
  if (self.version) {
    dictionary[kMSACVersion] = self.version;
  }
  if (self.shortVersion) {
    dictionary[kMSACShortVersion] = self.shortVersion;
  }
  if (self.releaseNotes) {
    dictionary[kMSACReleaseNotes] = self.releaseNotes;
  }
  if (self.provisioningProfileName) {
    dictionary[kMSACProvisioningProfileName] = self.provisioningProfileName;
  }
  if (self.size) {
    dictionary[kMSACSize] = self.size;
  }
  if (self.minOs) {
    dictionary[kMSACMinOs] = self.minOs;
  }
  dictionary[kMSACMandatoryUpdate] = @(self.mandatoryUpdate);
  if (self.fingerprint) {
    dictionary[kMSACFingerprint] = self.fingerprint;
  }
  if (self.uploadedAt) {
    dictionary[kMSACUploadedAt] = [MSACUtility dateToISO8601:(NSDate * _Nonnull) self.uploadedAt];
  }
  if (self.downloadUrl) {
    dictionary[kMSACDownloadUrl] = [self.downloadUrl absoluteString];
  }
  if (self.appIconUrl) {
    dictionary[kMSACAppIconUrl] = [self.appIconUrl absoluteString];
  }
  if (self.installUrl) {
    dictionary[kMSACInstallUrl] = [self.installUrl absoluteString];
  }
  if (self.releaseNotesUrl) {
    dictionary[kMSACReleaseNotesUrl] = [self.releaseNotesUrl absoluteString];
  }
  if (self.distributionGroupId) {
    dictionary[kMSACDistributionGroupId] = self.distributionGroupId;
  }
  if (self.distributionGroups) {

    // TODO: DistributionGroup has no properties so skip it until it has properties.
  }
  if (self.packageHashes) {
    dictionary[kMSACPackageHashes] = self.packageHashes;
  }
  return dictionary;
}

- (BOOL)isValid {
  return MSACLOG_VALIDATE_NOT_NIL(id) && MSACLOG_VALIDATE_NOT_NIL(downloadUrl);
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSACReleaseDetails class]]) {
    return NO;
  }
  MSACReleaseDetails *details = (MSACReleaseDetails *)object;
  return ((!self.id && !details.id) || [self.id isEqualToNumber:details.id]) &&
         ((!self.status && !details.status) || [self.status isEqualToString:details.status]) &&
         ((!self.appName && !details.appName) || [self.appName isEqualToString:details.appName]) &&
         ((!self.version && !details.version) || [self.version isEqualToString:details.version]) &&
         ((!self.shortVersion && !details.shortVersion) || [self.shortVersion isEqualToString:details.shortVersion]) &&
         ((!self.releaseNotes && !details.releaseNotes) || [self.releaseNotes isEqualToString:details.releaseNotes]) &&
         ((!self.provisioningProfileName && !details.provisioningProfileName) ||
          [self.provisioningProfileName isEqualToString:details.provisioningProfileName]) &&
         ((!self.size && !details.size) || [self.size isEqualToNumber:details.size]) &&
         ((!self.minOs && !details.minOs) || [self.minOs isEqualToString:details.minOs]) &&
         (self.mandatoryUpdate == details.mandatoryUpdate) &&
         ((!self.fingerprint && !details.fingerprint) || [self.fingerprint isEqualToString:details.fingerprint]) &&
         ((!self.uploadedAt && !details.uploadedAt) || [self.uploadedAt isEqual:details.uploadedAt]) &&

         // Don't compare downloadUrl. downloadUrl contains pltoken param which will have different values every time.
         // ((!self.downloadUrl && !details.downloadUrl) || [self.downloadUrl
         // isEqual:details.downloadUrl]) &&
         ((!self.appIconUrl && !details.appIconUrl) || [self.appIconUrl isEqual:details.appIconUrl]) &&
         ((!self.installUrl && !details.installUrl) || [self.installUrl isEqual:details.installUrl]) &&
         ((!self.releaseNotesUrl && !details.releaseNotesUrl) || [self.releaseNotesUrl isEqual:details.releaseNotesUrl]) &&

         // Don't compare distributionGroups. The property has no spec so it is not implemented yet.
         // ((!self.distributionGroups && !details.distributionGroups) ||
         //  [self.distributionGroups
         //  isEqualToArray:details.distributionGroups]) &&
         ((!self.packageHashes && !details.packageHashes) || [self.packageHashes isEqualToArray:details.packageHashes]);
}

@end
