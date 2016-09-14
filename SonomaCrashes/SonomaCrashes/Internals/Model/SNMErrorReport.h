/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface SNMErrorReport : NSObject

/**
 *  UUID for the crash report.
 */
@property(nonatomic, readonly) NSString *incidentIdentifier;

/**
 *  UUID for the app installation on the device.
 */
@property(nonatomic, readonly) NSString *reporterKey;

/**
 *  Signal that caused the crash.
 */
@property(nonatomic, readonly) NSString *signal;

/**
 *  Exception name that triggered the crash, nil if the crash was not caused by
 * an exception.
 */
@property(nonatomic, readonly) NSString *exceptionName;

/**
 *  Exception reason, nil if the crash was not caused by an exception.
 */
@property(nonatomic, readonly) NSString *exceptionReason;

/**
 *  Date and time the app started, nil if unknown.
 */
@property(nonatomic, readonly, strong) NSDate *appStartTime;

/**
 *  Date and time the crash occurred, nil if unknown
 */
@property(nonatomic, readonly, strong) NSDate *crashTime;

/**
 *  Operation System version string the app was running on when it crashed.
 */
@property(nonatomic, readonly) NSString *osVersion;

/**
 *  Operation System build string the app was running on when it crashed.
 *
 *  This may be unavailable.
 */
@property(nonatomic, readonly) NSString *osBuild;

/**
 *  CFBundleShortVersionString value of the app that crashed.
 *
 *  Can be `nil` if the crash was captured with an older version of the SDK
 *  or if the app doesn't set the value.
 */
@property(nonatomic, readonly) NSString *appVersion;

/**
 *  CFBundleVersion value of the app that crashed.
 */
@property(nonatomic, readonly) NSString *appBuild;

/**
 *  Identifier of the app process that crashed.
 */
@property(nonatomic, readonly, assign) NSUInteger appProcessIdentifier;

// TODO Please review this doc that contains method name which doesn't exist.
/**
 Indicates if the app was killed while being in foreground from the iOS.

 If `[SNMCrashes enableAppNotTerminatingCleanlyDetection]` is enabled, use this
 on startup
 to check if the app starts the first time after it was killed by iOS in the
 previous session.

 This can happen if it consumed too much memory or the watchdog killed the app
 because it
 took too long to startup or blocks the main thread for too long, or other
 reasons. See Apple
 documentation: https://developer.apple.com/library/ios/qa/qa1693/_index.html.

 See `[SNMCrashes enableAppNotTerminatingCleanlyDetection]` for more
 details about which kind of kills can be detected.

 @warning This property only has a correct value, once `[BITHockeyManager
 startManager]` was
 invoked! In addition, it is automatically disabled while a debugger session is
 active!

 @see `[SNMCrashes enableAppNotTerminatingCleanlyDetection]`
 @see `[SNMCrashes didReceiveMemoryWarningInLastSession]`

 @return YES if the details represent an app kill instead of a crash
 */
- (BOOL)isAppKill;

@end
