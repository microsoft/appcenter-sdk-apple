#import "MSUtility+Environment.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityEnvironmentCategory;

@implementation MSUtility (Environment)

+ (MSEnvironment)currentAppEnvironment {
#if TARGET_OS_SIMULATOR || TARGET_OS_OSX
  return MSEnvironmentOther;
#else

  // MobilePovision profiles are a clear indicator for Ad-Hoc distribution.
  if ([self hasEmbeddedMobileProvision]) {
    return MSEnvironmentOther;
  }

  /**
   * TestFlight is only supported from iOS 8 onwards and as our deployment target is iOS 8, we don't have to do any checks for
   * floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1).
   */
  if ([self isAppStoreReceiptSandbox]) {
    return MSEnvironmentTestFlight;
  }

  return MSEnvironmentAppStore;
#endif
}

+ (BOOL)hasEmbeddedMobileProvision {
  BOOL hasEmbeddedMobileProvision = !![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
  return hasEmbeddedMobileProvision;
}

+ (BOOL)isAppStoreReceiptSandbox {
#if TARGET_OS_SIMULATOR
  return NO;
#else
  if (![NSBundle.mainBundle respondsToSelector:@selector(appStoreReceiptURL)]) {
    return NO;
  }
  NSURL *appStoreReceiptURL = NSBundle.mainBundle.appStoreReceiptURL;
  NSString *appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent;

  BOOL isSandboxReceipt = [appStoreReceiptLastComponent isEqualToString:@"sandboxReceipt"];
  return isSandboxReceipt;
#endif
}

@end
