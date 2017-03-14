#import <CommonCrypto/CommonDigest.h>
#import "MSBasicMachOParser.h"
#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributeUtil.h"
#import "MSLogger.h"
#import "MSSemVer.h"
#import "MSUtil.h"

NSBundle *MSDistributeBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

    // The resource bundle is part of the main app bundle, e.g. .../Puppet.app/MobileCenterDistribute.bundle
    NSString *mainBundlePath = [[NSBundle bundleForClass:[MSDistribute class]] resourcePath];
    NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:MOBILE_CENTER_DISTRIBUTE_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];

    // Log to console in case the bundle is nil.
    if (!bundle) {
      MSLogError([MSDistribute logTag], @"The MobileCenterDistributeResources.bundle file could not be found in your"
                                         " app. Please add it to your project as described in our readme.");
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
   * Return the the localized string from the bundle if possible, return the stringToken in case we don't find a
   * localized string, or return an empty string.
   */
  NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
  if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
    return appSpecificLocalizationString;
  } else if (MSDistributeBundle()) {
    NSString *bundleSpecificLocalizationString =
        NSLocalizedStringFromTableInBundle(stringToken, @"MobileCenterDistribute", MSDistributeBundle(), @"");
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
  MSSemVer *shortVersionA =
      [MSSemVer semVerWithString:[MS_APP_MAIN_BUNDLE infoDictionary][@"CFBundleShortVersionString"]];
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
    if (result == NSOrderedSame && ![releaseB.packageHashes containsObject:packageHashA]) {
      return NSOrderedAscending;
    }
  }
  return result;
}

#pragma mark - Package hash

NSString *MSPackageHash(void) {

  /*
   * BuildUUID is different on every build with code changes.
   * For testing purposes you can update the related Safari cookie keys to the value of your choice
   * using JavaScript via Safari Web Inspector.
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
  return sha256([NSString stringWithFormat:@"%@:%@:%@", buildUUID, shortVersion, version]);
}

// TODO: Move this to MSUtil (MSUtility) once the branch gets merged from develop.
NSString *sha256(NSString *string) {

  // Hash string with SHA256.
  const char *encodedString = [string cStringUsingEncoding:NSASCIIStringEncoding];
  unsigned char hashedData[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(encodedString, strlen(encodedString), hashedData);

  // Convert hashed data to NSString.
  NSData *data = [NSData dataWithBytes:hashedData length:sizeof(hashedData)];
  NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
  const unsigned char *dataBuffer = [data bytes];
  for (NSUInteger i = 0; i < [data length]; i++) {
    [stringBuffer appendFormat:@"%02x", dataBuffer[i]];
  }
  return [stringBuffer copy];
}

@implementation MSDistributeUtil

@end
