/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSEnvironmentHelper.h"

@implementation MSEnvironmentHelper

//TODO add test for this

+ (SNMEnvironment)currentAppEnvironment {
#if TARGET_OS_SIMULATOR
  return SNMEnvironmentOther;
#else

  // MobilePovision profiles are a clear indicator for Ad-Hoc distribution.
  if ([self hasEmbeddedMobileProvision]) {
    return SNMEnvironmentOther;
  }

  /**
   * TestFlight is only supported from iOS 8 onwards and as our deployment target is iOS 8, we don't have to do any
   * checks for floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1).
  */
  if ([self isAppStoreReceiptSandbox]) {
    return SNMEnvironmentTestFlight;
  }

  return SNMEnvironmentAppStore;
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
