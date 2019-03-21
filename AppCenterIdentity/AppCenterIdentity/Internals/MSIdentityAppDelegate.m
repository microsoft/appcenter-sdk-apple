// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSIdentityAppDelegate.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSIdentityPrivate.h"

@implementation MSIdentityAppDelegate

#pragma mark - MSAppDelegate

- (BOOL)application:(__unused UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(__unused NSString *)sourceApplication
           annotation:(__unused id)annotation
        returnedValue:(BOOL)returnedValue {
  return [self openURL:url returnedValue:returnedValue];
}

- (BOOL)application:(__unused UIApplication *)application
            openURL:(NSURL *)url
            options:(__unused NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  return [self openURL:url returnedValue:returnedValue];
}

#pragma mark - Private

- (BOOL)openURL:(NSURL *)url returnedValue:(BOOL)returnedValue {

  MSLogDebug([MSIdentity logTag], @"Using swizzled openURL:returnedValue: method.");
  BOOL returnValue = [MSIdentity openURL:url];

  // Return original value if url not handled by the SDK.
  return (BOOL)(returnValue ?: returnedValue);
}

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSIdentity)

+ (void)load {

  // Register selectors to swizzle for Identity.
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [[MSAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
}

@end
