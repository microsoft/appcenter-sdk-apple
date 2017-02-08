/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@import Foundation;
@import UIKit;

#ifndef MSUtil_h
#define MSUtil_h

#define MS_USER_DEFAULTS [MSUserDefaults shared]
#define MS_NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#define MS_DEVICE [UIDevice currentDevice]
#define MS_UUID_STRING [[NSUUID UUID] UUIDString]
#define MS_UUID_FROM_STRING(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define MS_LOCALE [NSLocale currentLocale]
#define MS_CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:2]
#define MS_IS_APP_EXTENSION [[[NSBundle mainBundle] executablePath] containsString:@".appex/"]
#endif /* MSUtil_h */


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
 * Utility class that is used throughout the SDK.
 */
@interface MSUtil : NSObject

/**
 * Detect the environment that the app is running in.
 * @return the MSEnvironment of the app.
 */
+ (MSEnvironment)currentAppEnvironment;

/**
 * Get current application state.
 *
 * @discussion The application state may not be available anywhere. Application extensions doesn't have it for instance,
 * in that case the MSApplicationStateUnknown value is returned.
 * @return Current state of the application or MSApplicationStateUnknown while the state can't be determined.
 */
+ (MSApplicationState)applicationState;


/**
 * Return the current date (aka NOW) in ms.
 *
 * @discussion
 * Utility function that returns NOW as a NSTimeInterval but in ms instead of seconds with sub-ms precision. We're using NSTimeInterval
 * here instead of long long because we might be interested in sub-millisecond precision which we keep with NSTimeInterval as NSTimeInterval
 * is actually NSDouble.
 *
 * @return current time in ms with sub-ms precision if necessary
 */
+ (NSTimeInterval)nowInMilliseconds;

@end
