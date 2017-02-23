#import "MSUpdateUtil.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"

// Load the framework bundle.
NSBundle *MSUpdatesBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    NSString* mainBundlePath = [[NSBundle bundleForClass:[MSUpdates class]] resourcePath];
    NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:MOBILE_CENTER_UPDATES_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];
  });
  return bundle;
}

NSString *MSUpdatesLocalizedString(NSString *stringToken) {
  if (!stringToken) return @"";
  
  NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
  if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
    return appSpecificLocalizationString;
  } else if (MSUpdatesBundle()) {
    NSString *bundleSpecificLocalizationString = NSLocalizedStringFromTableInBundle(stringToken, @"MobileCenter", MSUpdatesBundle(), @"");
    if (bundleSpecificLocalizationString)
      return bundleSpecificLocalizationString;
    return stringToken;
  } else {
    return stringToken;
  }
}

