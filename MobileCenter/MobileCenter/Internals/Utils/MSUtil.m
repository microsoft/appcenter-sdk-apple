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

+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^__nullable)(BOOL success))completion {
  if (MS_IS_APP_EXTENSION) {
    completion(NO);
  }

  UIApplication *sharedApp = [[self class] sharedApp];
  SEL selector = NSSelectorFromString(@"openURL:options:completionHandler:");
  if ([sharedApp respondsToSelector:selector]) {
    NSInvocation *invocation =
        [NSInvocation invocationWithMethodSignature:[sharedApp methodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:sharedApp];
    [invocation setArgument:&url atIndex:2];
    [invocation setArgument:&options atIndex:3];
    [invocation setArgument:&completion atIndex:4];
    [invocation invoke];
  } else {
    BOOL success = [sharedApp performSelector:@selector(openURL:) withObject:url];
    if (completion) {
      completion(success);
    }
  }
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

@end
