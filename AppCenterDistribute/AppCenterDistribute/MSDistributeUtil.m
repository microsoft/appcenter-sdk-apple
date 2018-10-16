#import "MSBasicMachOParser.h"
#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributeUtil.h"
#import "MSLogger.h"
#import "MSSemVer.h"
#import "MSUtility+StringFormatting.h"

NSBundle *MSDistributeBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

    // The resource bundle is part of the main app bundle, e.g. .../Puppet.app/AppCenterDistribute.bundle
    NSString *mainBundlePath = [[NSBundle bundleForClass:[MSDistribute class]] resourcePath];
    NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:APP_CENTER_DISTRIBUTE_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];

    // Log to console in case the bundle is nil.
    if (!bundle) {
      MSLogError([MSDistribute logTag], @"The AppCenterDistributeResources.bundle file could not be found in your app. "
                                        @"Please add it to your project as described in our readme.");
    }
  });
  return bundle;
}

NSString *MSDistributeLocalizedString(NSString *stringToken) {

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
  } else if (MSDistributeBundle()) {
    NSString *bundleSpecificLocalizationString =
        NSLocalizedStringFromTableInBundle(stringToken, @"AppCenterDistribute", MSDistributeBundle(), @"");
    if (bundleSpecificLocalizationString)
      return bundleSpecificLocalizationString;
    return stringToken;
  } else {
    return stringToken;
  }
}

#pragma mark - Version comparison

NSComparisonResult MSCompareCurrentReleaseWithRelease(MSReleaseDetails *releaseB) {
  NSComparisonResult result = NSOrderedSame;
  MSSemVer *shortVersionA = [MSSemVer semVerWithString:[MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"]];
  MSSemVer *shortVersionB = [MSSemVer semVerWithString:releaseB.shortVersion];
  NSString *packageHashA = MSPackageHash();

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
      result = [(NSString *)[MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleVersion"] compare:releaseB.version options:NSNumericSearch];
    }

    // Still same, compare UUIDs.
    if (result == NSOrderedSame && ![releaseB.packageHashes containsObject:packageHashA]) {
      return NSOrderedAscending;
    }
  }
  return result;
}

#pragma mark - Package hash

NSString *MSPackageHash(void) {

  /*
   * BuildUUID is different on every build with code changes. For testing purposes you can update the related Safari cookie keys to the
   * value of your choice using JavaScript via Safari Web Inspector.
   */
  NSString *buildUUID = [[[MSBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];
  if (!buildUUID) {
    MSLogError([MSDistribute logTag], @"Cannot retrieve build UUID.");
    return nil;
  }

  // Read short version and version from bundle.
  NSString *shortVersion = [MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"];
  NSString *version = [MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleVersion"];
  if (!shortVersion || !version) {
    MSLogError([MSDistribute logTag], @"Cannot retrieve versions of the application.");
    return nil;
  }
  return [MSUtility sha256:[NSString stringWithFormat:@"%@:%@:%@", buildUUID, shortVersion, version]];
}

@implementation MSDistributeUtil

@end
