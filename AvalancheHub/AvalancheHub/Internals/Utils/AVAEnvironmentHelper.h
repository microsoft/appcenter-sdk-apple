/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  App environment
 */
typedef NS_ENUM(NSInteger, AVAEnvironment) {
  /**
   *  App has been downloaded from the AppStore.
   */
  AVAEnvironmentAppStore = 0,
  /**
   *  App has been downloaded from TestFlight.
   */
  AVAEnvironmentTestFlight = 1,
  /**
   *  App has been installed by some other mechanism.
   *  This could be Ad-Hoc, Enterprise, etc.
   */
  AVAEnvironmentOther = 99
};

/**
 * Utility class to detect environment that the app is running in. It's used to enable/disable features throughout the
 * SDK.
 */
@interface AVAEnvironmentHelper : NSObject

/**
 * Detect the environment that the app is running in.
 * @return the AVAEnvironment of the app.
 */
+ (AVAEnvironment)currentAppEnvironment;

@end
