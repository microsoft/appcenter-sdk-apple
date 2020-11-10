// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeAppDelegate.h"
#import "MSACAppDelegateForwarder.h"
#import "MSACDistribute.h"

@implementation MSACDistributeAppDelegate

#pragma mark - MSACAppDelegate

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
  BOOL returnValue = [MSACDistribute openURL:url];

  // Return original value if url not handled by the SDK.
  return (BOOL)(returnValue ?: returnedValue);
}

@end

#pragma mark - Swizzling

@implementation MSACAppDelegateForwarder (MSACDistribute)

+ (void)load {

  // Register selectors to swizzle for Distribute.
  [[MSACAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [[MSACAppDelegateForwarder sharedInstance] addDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
}

@end
