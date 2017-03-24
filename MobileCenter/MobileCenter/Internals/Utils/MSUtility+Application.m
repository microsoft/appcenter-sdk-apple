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

+ (UIApplicationState)sharedAppState {
  return [[[[self class] sharedApp] valueForKey:@"applicationState"] longValue];
}

+ (UIApplication *)sharedApp {

  // Compute selector at runtime for more discretion.
  SEL sharedAppSel = NSSelectorFromString(@"sharedApplication");
  return ((UIApplication * (*)(id, SEL))[[UIApplication class] methodForSelector:sharedAppSel])([UIApplication class],
                                                                                                sharedAppSel);
}

+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^__nullable)(BOOL success))completion {

  // FIXME: App extensions does support openURL through NSExtensionContest, we may use this somehow.
  if (MS_IS_APP_EXTENSION) {
    completion(NO);
    return;
  }

  /* Dispatch the open url call to the next loop to avoid freezing the App new instance start up */
  dispatch_async(dispatch_get_main_queue(), ^{
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
  });
}

@end
