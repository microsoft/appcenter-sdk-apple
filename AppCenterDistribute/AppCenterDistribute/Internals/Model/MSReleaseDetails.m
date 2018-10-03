#import "MSDistributionGroup.h"
#import "MSReleaseDetailsPrivate.h"
#import "MSUtility+Date.h"

static NSString *const kMSId = @"id";
static NSString *const kMSStatus = @"status";
static NSString *const kMSAppName = @"app_name";
static NSString *const kMSVersion = @"version";
static NSString *const kMSShortVersion = @"short_version";
static NSString *const kMSReleaseNotes = @"release_notes";
static NSString *const kMSProvisioningProfileName = @"provisioning_profile_name";
static NSString *const kMSSize = @"size";
static NSString *const kMSMinOs = @"min_os";
static NSString *const kMSMandatoryUpdate = @"mandatory_update";
static NSString *const kMSFingerprint = @"fingerprint";
static NSString *const kMSUploadedAt = @"uploaded_at";
static NSString *const kMSDownloadUrl = @"download_url";
static NSString *const kMSAppIconUrl = @"app_icon_url";
static NSString *const kMSInstallUrl = @"install_url";
static NSString *const kMSReleaseNotesUrl = @"release_notes_url";
static NSString *const kMSDistributionGroupId = @"distribution_group_id";
static NSString *const kMSDistributionGroups = @"distribution_groups";
static NSString *const kMSPackageHashes = @"package_hashes";

@implementation MSReleaseDetails

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
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
      if ([(NSObject *)dictionary[kMSReleaseNotes] isKindOfClass:[NSNull class]]) {
        self.releaseNotes = nil;
      } else {
        self.releaseNotes = dictionary[kMSReleaseNotes];
      }
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
    if (dictionary[kMSMandatoryUpdate]) {
      self.mandatoryUpdate = [(NSObject *)dictionary[kMSMandatoryUpdate] isEqual:@YES] ? YES : NO;
    }
    if (dictionary[kMSFingerprint]) {
      self.fingerprint = dictionary[kMSFingerprint];
    }
    if (dictionary[kMSUploadedAt]) {
      NSString *_Nonnull uploadedAt = (NSString * _Nonnull)dictionary[kMSUploadedAt];
      self.uploadedAt = [MSUtility dateFromISO8601:uploadedAt];
    }
    if (dictionary[kMSDownloadUrl]) {
      if ([(NSObject *)dictionary[kMSDownloadUrl] isKindOfClass:[NSNull class]]) {
        self.downloadUrl = nil;
      } else {
        NSString *_Nonnull downloadUrl = (NSString * _Nonnull)dictionary[kMSDownloadUrl];
        self.downloadUrl = [NSURL URLWithString:downloadUrl];
      }
    }
    if (dictionary[kMSAppIconUrl]) {
      if ([(NSObject *)dictionary[kMSAppIconUrl] isKindOfClass:[NSNull class]]) {
        self.appIconUrl = nil;
      } else {
        NSString *_Nonnull appIconUrl = (NSString * _Nonnull)dictionary[kMSAppIconUrl];
        self.appIconUrl = [NSURL URLWithString:appIconUrl];
      }
    }
    if (dictionary[kMSInstallUrl]) {
      if ([(NSObject *)dictionary[kMSInstallUrl] isKindOfClass:[NSNull class]]) {
        self.installUrl = nil;
      } else {
        NSString *_Nonnull installUrl = (NSString * _Nonnull)dictionary[kMSInstallUrl];
        self.installUrl = [NSURL URLWithString:installUrl];
      }
    }
    if (dictionary[kMSReleaseNotesUrl]) {
      if ([(NSObject *)dictionary[kMSReleaseNotesUrl] isKindOfClass:[NSNull class]]) {
        self.releaseNotesUrl = nil;
      } else {
        NSString *_Nonnull releaseNotesUrl = (NSString * _Nonnull)dictionary[kMSReleaseNotesUrl];
        self.releaseNotesUrl = [NSURL URLWithString:releaseNotesUrl];
      }
    }
    if (dictionary[kMSDistributionGroupId]) {
      self.distributionGroupId = dictionary[kMSDistributionGroupId];
    }
    if (dictionary[kMSDistributionGroups]) {

      // TODO: DistributionGroup has no properties so skip it until it has properties.
    }
    if (dictionary[kMSPackageHashes]) {
      self.packageHashes = dictionary[kMSPackageHashes];
    }
  }
  return self;
}

- (NSDictionary *)serializeToDictionary {
  NSMutableDictionary *dictionary = [NSMutableDictionary new];

  // Fill in the dictionary with properties.
  if (self.id) {
    dictionary[kMSId] = self.id;
  }
  if (self.status) {
    dictionary[kMSStatus] = self.status;
  }
  if (self.appName) {
    dictionary[kMSAppName] = self.appName;
  }
  if (self.version) {
    dictionary[kMSVersion] = self.version;
  }
  if (self.shortVersion) {
    dictionary[kMSShortVersion] = self.shortVersion;
  }
  if (self.releaseNotes) {
    dictionary[kMSReleaseNotes] = self.releaseNotes;
  }
  if (self.provisioningProfileName) {
    dictionary[kMSProvisioningProfileName] = self.provisioningProfileName;
  }
  if (self.size) {
    dictionary[kMSSize] = self.size;
  }
  if (self.minOs) {
    dictionary[kMSMinOs] = self.minOs;
  }
  dictionary[kMSMandatoryUpdate] = @(self.mandatoryUpdate);
  if (self.fingerprint) {
    dictionary[kMSFingerprint] = self.fingerprint;
  }
  if (self.uploadedAt) {
    dictionary[kMSUploadedAt] = [MSUtility dateToISO8601:(NSDate * _Nonnull)self.uploadedAt];
  }
  if (self.downloadUrl) {
    dictionary[kMSDownloadUrl] = [self.downloadUrl absoluteString];
  }
  if (self.appIconUrl) {
    dictionary[kMSAppIconUrl] = [self.appIconUrl absoluteString];
  }
  if (self.installUrl) {
    dictionary[kMSInstallUrl] = [self.installUrl absoluteString];
  }
  if (self.releaseNotesUrl) {
    dictionary[kMSReleaseNotesUrl] = [self.releaseNotesUrl absoluteString];
  }
  if (self.distributionGroupId) {
    dictionary[kMSDistributionGroupId] = self.distributionGroupId;
  }
  if (self.distributionGroups) {

    // TODO: DistributionGroup has no properties so skip it until it has properties.
  }
  if (self.packageHashes) {
    dictionary[kMSPackageHashes] = self.packageHashes;
  }
  return dictionary;
}

- (BOOL)isValid {
  return (self.id && self.downloadUrl);
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSReleaseDetails class]]) {
    return NO;
  }
  MSReleaseDetails *details = (MSReleaseDetails *)object;
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
