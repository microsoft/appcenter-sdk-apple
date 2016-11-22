/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>

/**
 *  App states
 */
typedef NS_ENUM(NSInteger, MSApplicationState) {

  /**
   * Application is active.
   */
  MSApplicationStateActive = UIApplicationStateActive,

  /**
   * Application is inactive.
   */
  MSApplicationStateInactive = UIApplicationStateInactive,

  /**
   * Application is in background.
   */
  MSApplicationStateBackground = UIApplicationStateBackground,

  /**
   * Application state can't be determined.
   */
  MSApplicationStateUnknown
};

/**
 * Utility class to access application APIs.
 */
@interface MSApplicationHelper : NSObject

/**
 * Get current application state.
 *
 * @discussion The application state may not be available anywhere. Application extensions doesn't have it for instance,
 * in that case the MSApplicationStateUnknown value is returned.
 * @return Current state of the application or MSApplicationStateUnknown while the state can't be determined.
 */
+ (MSApplicationState)applicationState;

@end