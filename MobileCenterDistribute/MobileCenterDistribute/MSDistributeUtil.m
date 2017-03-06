#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributeUtil.h"
#import "MSLogger.h"

NSBundle *MSDistributeBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

    // The resource bundle is part of the main app bundle, e.g. .../Puppet.app/MobileCenterDistribute.bundle
    NSString *mainBundlePath = [[NSBundle bundleForClass:[MSDistribute class]] resourcePath];
    NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:MOBILE_CENTER_DISTRIBUTE_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];
    
    // Log to console in case the bundle is nil.
    if(!bundle) {
      MSLogWarning([MSDistribute logTag], @"The MobileCenterDistributeResources.bundle file could not be found in your"
              " app. Please it to your project as described in our readme.");
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
