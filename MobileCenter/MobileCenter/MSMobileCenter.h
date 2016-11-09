/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSConstants.h"
#import <Foundation/Foundation.h>

@class MSWrapperSdk;

/**
 * Class comment: Some Introduction.
 */
@interface MSMobileCenter : NSObject

/**
 * Returns the singleton instance of MSMobileCenter.
 */
+ (instancetype)sharedInstance;

/**
 * Start the SDK.
 *
 * @param appSecret application secret.
 */
+ (void)start:(NSString *)appSecret;

/**
 * Start the SDK with services.
 *
 * @param appSecret Application secret.
 * @param services  Array of services to be used.
 */
+ (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services;

/**
 * Start a service.
 *
 * @param service  A service to be used.
 */
+ (void)startService:(Class)service;

/**
 * Check whether the SDK has already been initialized or not.
 *
 * @return YES if initialized, NO otherwise.
 */
+ (BOOL)isInitialized;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param serverUrl base URL to use for backend communication.
 */
+ (void)setServerUrl:(NSString *)serverUrl;

/**
 * Enable or disable the SDK as a whole. In addition to the core resources, it will also enable or disable all
 * registered services.
 *
 * @param isEnabled YES to enable, NO to disable.
 * @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 *  Check whether the SDK is enabled or not as a whole.
 *
 * @return YES if enabled, NO otherwise.
 * @see setEnabled:
 */
+ (BOOL)isEnabled;

/**
 * Get log level.
 *
 * @return log level.
 */
+ (MSLogLevel)logLevel;

/**
 * Set log level.
 *
 * @param logLevel the log level.
 */
+ (void)setLogLevel:(MSLogLevel)logLevel;

/**
 * Set log level handler.
 *
 * @param logHandler handler.
 */
+ (void)setLogHandler:(MSLogHandler)logHandler;

/**
 * Set wrapper SDK information to use when building device properties. This is intended in case you are building a SDK
 * that uses the Mobile Center SDK under the hood, e.g. our Xamarin SDK or ReactNative SDk.
 *
 * @param wrapperSdk wrapper SDK information.
 */
+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk;

/**
 * Get unique installation identifier.
 *
 * @return unique installation identifier.
 */
+ (NSUUID *)installId;

/**
 * Detect if a debugger is attached to the app process. This is only invoked once on app startup and can not detect
 * if the debugger is being attached during runtime!
 *
 * @return BOOL if the debugger is attached.
 */
+ (BOOL)isDebuggerAttached;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+(void)resetSharedInstance;


@end
