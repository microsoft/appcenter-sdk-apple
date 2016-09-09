/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  App environment
 */
typedef NS_ENUM(NSInteger, SNMEnvironment) {
  /**
   *  App has been downloaded from the AppStore.
   */
  SNMEnvironmentAppStore = 0,
  /**
   *  App has been downloaded from TestFlight.
   */
  SNMEnvironmentTestFlight = 1,
  /**
   *  App has been installed by some other mechanism.
   *  This could be Ad-Hoc, Enterprise, etc.
   */
  SNMEnvironmentOther = 99
};

/**
 * Utility class to detect environment that the app is running in. It's used to enable/disable features throughout the
 * SDK.
 */
@interface SNMEnvironmentHelper : NSObject

/**
 * Detect the environment that the app is running in.
 * @return the SNMEnvironment of the app.
 */
+ (SNMEnvironment)currentAppEnvironment;

@end
