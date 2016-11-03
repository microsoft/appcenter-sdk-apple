/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  App environment
 */
typedef NS_ENUM(NSInteger, MSEnvironment) {
  /**
   *  App has been downloaded from the AppStore.
   */
  MSEnvironmentAppStore = 0,
  /**
   *  App has been downloaded from TestFlight.
   */
  MSEnvironmentTestFlight = 1,
  /**
   *  App has been installed by some other mechanism.
   *  This could be Ad-Hoc, Enterprise, etc.
   */
  MSEnvironmentOther = 99
};

/**
 * Utility class to detect environment that the app is running in. It's used to enable/disable features throughout the
 * SDK.
 */
@interface MSEnvironmentHelper : NSObject

/**
 * Detect the environment that the app is running in.
 * @return the MSEnvironment of the app.
 */
+ (MSEnvironment)currentAppEnvironment;

@end
