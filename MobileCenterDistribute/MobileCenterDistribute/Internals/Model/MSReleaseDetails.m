#import "MSDistributionGroup.h"
#import "MSReleaseDetails.h"

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
      if ([dictionary[kMSReleaseNotes] isKindOfClass:[NSNull class]]) {
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
      self.mandatoryUpdate = [dictionary[kMSMandatoryUpdate] isEqual:@YES] ? YES : NO;
    }
    if (dictionary[kMSFingerprint]) {
      self.fingerprint = dictionary[kMSFingerprint];
    }
    if (dictionary[kMSUploadedAt]) {
      NSDateFormatter *formatter = [NSDateFormatter new];
      [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
      NSString *_Nonnull uploadedAt = (NSString * _Nonnull)dictionary[kMSUploadedAt];
      self.uploadedAt = [formatter dateFromString:uploadedAt];
    }
    if (dictionary[kMSDownloadUrl]) {
      NSString *_Nonnull downloadUrl = (NSString * _Nonnull)dictionary[kMSDownloadUrl];
      self.downloadUrl = [NSURL URLWithString:downloadUrl];
    }
    if (dictionary[kMSAppIconUrl]) {
      NSString *_Nonnull appIconUrl = (NSString * _Nonnull)dictionary[kMSAppIconUrl];
      self.appIconUrl = [NSURL URLWithString:appIconUrl];
    }
    if (dictionary[kMSInstallUrl]) {
      NSString *_Nonnull installUrl = (NSString * _Nonnull)dictionary[kMSInstallUrl];
      self.installUrl = [NSURL URLWithString:installUrl];
    }
    if (dictionary[kMSDistributionGroups]) {
      // TODO: Implement here. There is no spec for DistributionGroup data model.
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
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    dictionary[kMSUploadedAt] = [formatter stringFromDate:(NSDate * _Nonnull)self.uploadedAt];
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
  if (self.distributionGroups) {
    // TODO: Implement here. There is no spec for DistributionGroup data model.
  }
  if (self.packageHashes) {
    dictionary[kMSPackageHashes] = self.packageHashes;
  }
  return dictionary;
}

- (BOOL)isValid {
  return (self.id && self.downloadUrl);
}
@end
