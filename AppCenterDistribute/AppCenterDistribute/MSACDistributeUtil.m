// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeUtil.h"
#import "MSACBasicMachOParser.h"
#import "MSACDistributeInternal.h"
#import "MSACDistributePrivate.h"
#import "MSACLogger.h"
#import "MSACSemVer.h"
#import "MSACUtility+StringFormatting.h"

NSBundle *MSACDistributeBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

  // The resource bundle is part of the main app bundle, e.g. .../Puppet.app/AppCenterDistribute.bundle
#ifdef SWIFTPM_MODULE_BUNDLE
    bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *mainBundle = [NSBundle bundleForClass:[MSACDistribute class]];
    NSURL *url = [mainBundle URLForResource:APP_CENTER_DISTRIBUTE_BUNDLE_NAME withExtension:@"bundle"];
    if (url) {
      bundle = [NSBundle bundleWithURL:url];
    }

    // Log to console in case the bundle is nil.
    if (!bundle) {
      MSACLogError([MSACDistribute logTag], @"The AppCenterDistributeResources.bundle file could not be found in your app. "
                                            @"Please add it to your project as described in our readme.");
    }
#endif
  });
  return bundle;
}

NSString *MSACDistributeLocalizedString(NSString *stringToken) {

  // Return an empty string in case our token is nil.
  if (!stringToken) {
    return @"";
  }

  /*
   * Return the the localized string from the bundle if possible, return the stringToken in case we don't find a localized string, or return
   * an empty string.
   */
  NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
  if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
    return appSpecificLocalizationString;
  } else if (MSACDistributeBundle()) {
    NSString *bundleSpecificLocalizationString =
        NSLocalizedStringFromTableInBundle(stringToken, @"AppCenterDistribute", MSACDistributeBundle(), @"");
    if (bundleSpecificLocalizationString)
      return bundleSpecificLocalizationString;
    return stringToken;
  } else {
    return stringToken;
  }
}

#pragma mark - Version comparison

NSComparisonResult MSACCompareCurrentReleaseWithRelease(MSACReleaseDetails *releaseB) {
  NSComparisonResult result = NSOrderedSame;
  MSACSemVer *shortVersionA = [MSACSemVer semVerWithString:[MSAC_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"]];
  MSACSemVer *shortVersionB = [MSACSemVer semVerWithString:releaseB.shortVersion];
  NSString *packageHashA = MSACPackageHash();

  // Compare.
  if (!shortVersionA) {

    // None is using semantic versioning format, compare UUIDs.
    if (!shortVersionB) {
      if (![releaseB.packageHashes containsObject:packageHashA]) {
        return NSOrderedAscending;
      }
    } else {

      // Only version B is semantic versioning.
      return NSOrderedAscending;
    }
  } else if (!shortVersionB) {

    // Only version A is semantic versioning.
    return NSOrderedDescending;
  } else {

    // Compare using semantic versioning.
    result = [shortVersionA compare:shortVersionB];

    // Same, use version field as numeric values for comparison.
    if (result == NSOrderedSame) {
      result = [(NSString *)[MSAC_APP_MAIN_BUNDLE infoDictionary][@"CFBundleVersion"] compare:releaseB.version options:NSNumericSearch];
    }

    // Still same, compare UUIDs.
    if (result == NSOrderedSame && ![releaseB.packageHashes containsObject:packageHashA]) {
      return NSOrderedAscending;
    }
  }
  return result;
}

#pragma mark - Package hash

NSString *MSACPackageHash(void) {

  /*
   * BuildUUID is different on every build with code changes. For testing purposes you can update the related Safari cookie keys to the
   * value of your choice using JavaScript via Safari Web Inspector.
   */
  NSString *buildUUID = [[[MSACBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];
  if (!buildUUID) {
    MSACLogError([MSACDistribute logTag], @"Cannot retrieve build UUID.");
    return nil;
  }

  // Read short version and version from bundle.
  NSString *shortVersion = [MSAC_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"];
  NSString *version = [MSAC_APP_MAIN_BUNDLE infoDictionary][@"CFBundleVersion"];
  if (!shortVersion || !version) {
    MSACLogError([MSACDistribute logTag], @"Cannot retrieve versions of the application.");
    return nil;
  }
  return [MSACUtility sha256:[NSString stringWithFormat:@"%@:%@:%@", buildUUID, shortVersion, version]];
}

@implementation MSACDistributeUtil

+ (BOOL)isValidUpdateTrack:(MSACUpdateTrack)updateTrack {
  return updateTrack == MSACUpdateTrackPublic || updateTrack == MSACUpdateTrackPrivate;
}

@end
