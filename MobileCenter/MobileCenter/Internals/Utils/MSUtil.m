#import <Foundation/Foundation.h>

#import "MSUtilPrivate.h"

static short const kMSUUIDDashIndexes[] = {8, 13, 18, 23};
static short const kMSUUIDLength = 36;
static NSString *const kMSUUIDSeparator = @"-";

@implementation MSUtil

#pragma mark - App Environment Utility Methods

+ (MSEnvironment)currentAppEnvironment {
#if TARGET_OS_SIMULATOR
  return MSEnvironmentOther;
#else

  // MobilePovision profiles are a clear indicator for Ad-Hoc distribution.
  if ([self hasEmbeddedMobileProvision]) {
    return MSEnvironmentOther;
  }

  /**
   * TestFlight is only supported from iOS 8 onwards and as our deployment target is iOS 8, we don't have to do any
   * checks for floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1).
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

#pragma mark - UIApplication Utility Methods

+ (MSApplicationState)applicationState {

  // App extentions must not access sharedApplication.
  if (!MS_IS_APP_EXTENSION) {
    return (MSApplicationState)[[self class] sharedAppState];
  }
  return MSApplicationStateUnknown;
}

+ (UIApplicationState)sharedAppState {
  return [[[[self class] sharedApp] valueForKey:@"applicationState"] longValue];
}

+ (void)sharedAppOpenURL:(NSURL *)url {
  if (!MS_IS_APP_EXTENSION) {
    [[[self class] sharedApp] performSelector:@selector(openURL:) withObject:url];
  }
}

+ (BOOL)sharedAppCanOpenURL:(NSURL *)url {
  if (MS_IS_APP_EXTENSION) {
    return NO;
  }
  return [[[self class] sharedApp] performSelector:@selector(canOpenURL:) withObject:url];
}

+ (UIApplication *)sharedApp {

  // Compute selector at runtime for more discretion.
  SEL sharedAppSel = NSSelectorFromString(@"sharedApplication");
  return ((UIApplication * (*)(id, SEL))[[UIApplication class] methodForSelector:sharedAppSel])([UIApplication class],
                                                                                                sharedAppSel);
}

#pragma mark - Date Utility Methods

+ (NSTimeInterval)nowInMilliseconds {
  return ([[NSDate date] timeIntervalSince1970] * 1000);
}

#pragma mark - Format Utility Methods

+ (NSString *)formatToUUIDString:(NSString *)aString {
  NSMutableString *stringToFormat = [aString mutableCopy];
  short dashesCount = (sizeof kMSUUIDDashIndexes) / (sizeof kMSUUIDDashIndexes[0]);

  // Pre-validate string.
  if (aString.length != (NSUInteger)(kMSUUIDLength - dashesCount)) {
    return nil;
  }
  for (short i = 0; i < dashesCount; i++) {
    [stringToFormat insertString:kMSUUIDSeparator atIndex:kMSUUIDDashIndexes[i]];
  }

  // Validate final UUID string.
  if (![[NSUUID alloc] initWithUUIDString:stringToFormat]) {
    return nil;
  }
  return [stringToFormat copy];
}

@end
