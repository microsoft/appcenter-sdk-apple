#import "MSDistributeAppDelegate.h"
#import "MSAppDelegateForwarder.h"
#import "MSDistribute.h"

@implementation MSDistributeAppDelegate

#pragma mark - MSAppDelegate

- (BOOL)application:(__attribute__((unused))UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(__attribute__((unused))NSString *)sourceApplication
           annotation:(__attribute__((unused))id)annotation
        returnedValue:(BOOL)returnedValue {
  return [self openURL:url returnedValue:returnedValue];
}

- (BOOL)application:(__attribute__((unused))UIApplication *)application
            openURL:(NSURL *)url
            options:(__attribute__((unused))NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  return [self openURL:url returnedValue:returnedValue];
}

#pragma mark - Private

- (BOOL)openURL:(NSURL *)url returnedValue:(BOOL)returnedValue {
  BOOL returnValue = [MSDistribute openURL:url];

  // Return original value if url not handled by the SDK.
  return (BOOL)(returnValue ?: returnedValue);
}

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSDistribute)

+ (void)load {

  // Register selectors to swizzle for Distribute.
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
}

@end
