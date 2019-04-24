// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthAppDelegate.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSAuthPrivate.h"

@implementation MSAuthAppDelegate

#pragma mark - MSAppDelegate

- (BOOL)application:(__unused UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(__unused id)annotation
        returnedValue:(BOOL)returnedValue {
  NSDictionary *options = @{UIApplicationOpenURLOptionsSourceApplicationKey : sourceApplication};
  return [self openURL:url options:options returnedValue:returnedValue];
}

- (BOOL)application:(__unused UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  return [self openURL:url options:options returnedValue:returnedValue];
}

#pragma mark - Private

- (BOOL)openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options returnedValue:(BOOL)returnedValue {

  MSLogDebug([MSAuth logTag], @"Using swizzled openURL:returnedValue: method.");
  BOOL returnValue = [MSAuth openURL:url options:options];

  // Return original value if url not handled by the SDK.
  return (BOOL)(returnValue ?: returnedValue);
}

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSAuth)

+ (void)load {

  // Register selectors to swizzle for Auth.
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
}

@end
