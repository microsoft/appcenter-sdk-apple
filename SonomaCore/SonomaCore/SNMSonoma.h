/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants.h"
#import <Foundation/Foundation.h>

@class SNMWrapperSdk;

/**
 * Class comment: Some Introduction.
 */
@interface SNMSonoma : NSObject

/**
 * Returns the singleton instance of SonomaCore.
 */
+ (instancetype)sharedInstance;

/**
 * Start the SDK.
 *
 * @param appSecret application secret.
 */
+ (void)start:(NSString *)appSecret;

/**
 * Start the SDK with features.
 *
 * @param appSecret application secret.
 * @param features  array of features to be used.
 */
+ (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features;

/**
 * Start a feature.
 *
 * @param feature  a feature to be used.
 */
+ (void)startFeature:(Class)feature;

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
 * registered features.
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
+ (SNMLogLevel)logLevel;

/**
 * Set log level.
 *
 * @param logLevel the log level.
 */
+ (void)setLogLevel:(SNMLogLevel)logLevel;

/**
 * Set log level handler.
 *
 * @param logHandler handler.
 */
+ (void)setLogHandler:(SNMLogHandler)logHandler;

/**
 * Set wrapper SDK information to use when building device properties. This is intended in case you are building a SDK
 * that uses the Sonoma SDK under the hood, e.g. our Xamarin SDK or ReactNative SDk.
 *
 * @param wrapperSdk wrapper SDK information.
 */
+ (void)setWrapperSdk:(SNMWrapperSdk *)wrapperSdk;

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

@end
