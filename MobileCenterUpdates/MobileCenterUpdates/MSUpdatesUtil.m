#import "MSBasicMachOParser.h"
#import "MSSemVer.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"
#import "MSUpdatesUtil.h"
#import "MSUtil.h"

NSBundle *MSUpdatesBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

    // The resource bundle is part of the main app bundle, e.g. .../Puppet.app/MobileCenterUpdates.bundle
    NSString *mainBundlePath = [[NSBundle bundleForClass:[MSUpdates class]] resourcePath];
    NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:MOBILE_CENTER_UPDATES_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];
  });
  return bundle;
}

NSString *MSUpdatesLocalizedString(NSString *stringToken) {

  // Return an empty string in case our token is nil.
  if (!stringToken) {
    return @"";
  }

  /*
   * Return the the localized string from the bundle if possible, return the stringToken in case we don't find a
   * localized string, or return an empty string.
   */
  NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
  if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
    return appSpecificLocalizationString;
  } else if (MSUpdatesBundle()) {
    NSString *bundleSpecificLocalizationString =
        NSLocalizedStringFromTableInBundle(stringToken, @"MobileCenterUpdates", MSUpdatesBundle(), @"");
    if (bundleSpecificLocalizationString)
      return bundleSpecificLocalizationString;
    return stringToken;
  } else {
    return stringToken;
  }
}

#pragma mark - Version comparison Utility Methods

NSComparisonResult MSCompareCurrentReleaseWithRelease(MSReleaseDetails *releaseB) {
  NSComparisonResult result = NSOrderedSame;
  MSSemVer *shortVersionA =
      [MSSemVer semVerWithString:[MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"]];
  MSSemVer *shortVersionB = [MSSemVer semVerWithString:releaseB.shortVersion];
  NSString *releaseAUUID = [[[MSBasicMachOParser machOParserForMainBundle].uuid UUIDString] lowercaseString];

  // Compare.
  if (!shortVersionA) {

    // None is using semantic versioning format, compare UUIDs.
    if (!shortVersionB) {
      if (![releaseB.packageHashes containsObject:releaseAUUID]) {
        return NSOrderedAscending;
      }
    } else {

      // Only verison B is semantic versioning.
      return NSOrderedAscending;
    }
  } else if (!shortVersionB) {

    // Only verison A is semantic versioning.
    return NSOrderedDescending;
  } else {

    // Compare using semantic versioning.
    result = [shortVersionA compare:shortVersionB];

    // Same, use version field as numeric values for comparison.
    if (result == NSOrderedSame) {
      result =
          [[MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleVersion"] compare:releaseB.version options:NSNumericSearch];
    }

    // Still same, compare UUIDs.
    if (result == NSOrderedSame && ![releaseB.packageHashes containsObject:releaseAUUID]) {
      return NSOrderedAscending;
    }
  }
  return result;
}
