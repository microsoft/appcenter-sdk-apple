#import "MSUtility+ApplicationPrivate.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityApplicationCategory;

@implementation MSUtility (Application)

+ (MSApplicationState)applicationState {

  // App extensions must not access sharedApplication.
  if (!MS_IS_APP_EXTENSION) {
    return (MSApplicationState)[[self class] sharedAppState];
  }
  return MSApplicationStateUnknown;
}

+ (MSApplicationState)sharedAppState {
  return [[[self class] sharedApp] isHidden] ? MSApplicationStateBackground : MSApplicationStateActive;
}

+ (NSApplication *)sharedApp {

  // Compute selector at runtime for more discretion.
  SEL sharedAppSel = NSSelectorFromString(@"sharedApplication");
  return ((NSApplication * (*)(id, SEL))[[NSApplication class] methodForSelector:sharedAppSel])([NSApplication class],
                                                                                                sharedAppSel);
}

+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^)(MSOpenURLState state))completion {
  (void)options;

  /*
   * TODO: iOS SDK has an issue that openURL returns NO even though it was able to open a browser. Need to make sure
   * openURL returns YES/NO on macOS properly.
   */
  // Dispatch the open url call to the next loop to avoid freezing the App new instance start up.
  dispatch_async(dispatch_get_main_queue(), ^{
    completion([[NSWorkspace sharedWorkspace] openURL:url]);
  });
}

@end
