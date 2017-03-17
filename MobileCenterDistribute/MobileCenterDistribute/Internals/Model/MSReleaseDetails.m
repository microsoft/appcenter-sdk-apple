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
      self.uploadedAt = [formatter dateFromString:dictionary[kMSUploadedAt]];
    }
    if (dictionary[kMSDownloadUrl]) {
      self.downloadUrl = [NSURL URLWithString:dictionary[kMSDownloadUrl]];
    }
    if (dictionary[kMSAppIconUrl]) {
      self.appIconUrl = [NSURL URLWithString:dictionary[kMSAppIconUrl]];
    }
    if (dictionary[kMSInstallUrl]) {
      self.installUrl = [NSURL URLWithString:dictionary[kMSInstallUrl]];
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

- (BOOL)isValid {
  return (self.id && self.downloadUrl);
}

@end
