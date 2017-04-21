#import "MSUtility+ApplicationPrivate.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityApplicationCategory;

@implementation MSUtility (Application)

+ (MSApplicationState)applicationState {

  // App extentions must not access sharedApplication.
  if (!MS_IS_APP_EXTENSION) {
    return (MSApplicationState)[[self class] sharedAppState];
  }
  return MSApplicationStateUnknown;
}

// TODO: Always return MSApplicationStateActive for now. Need an actual implementation when we support macOS officially.
+ (MSApplicationState)sharedAppState {
  return MSApplicationStateActive;
}

+ (NSApplication *)sharedApp {
  return [NSApplication sharedApplication];
}

+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^)(MSOpenURLState state))completion {
  (void)options;

  /*
   * TODO: iOS SDK has an issue that openURL returns NO even though it was able to open a browser. Need to make sure
   * openURL returns YES/NO properly.
   */
  // Dispatch the open url call to the next loop to avoid freezing the App new instance start up.
  dispatch_async(dispatch_get_main_queue(), ^{
    completion([[NSWorkspace sharedWorkspace] openURL:url]);
  });
}

@end
