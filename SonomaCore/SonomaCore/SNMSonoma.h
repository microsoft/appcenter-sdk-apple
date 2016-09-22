/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants.h"
#import <Foundation/Foundation.h>

/**
 Class comment: Some Introduction
 */
@interface SNMSonoma : NSObject

/**
 * Returns the singleton instance of SonomaCore.
 */
+ (instancetype)sharedInstance;

/**
 *  Start the SDK
 *
 *  @param appSecret application secret.
 *  @param features  array of features to be used.
 */
+ (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features;

/**
 *  Enable or disable the SDK as a whole. In addition to the core resources, it will also enable or disable all
 * registered features.
 *
 *  @param isEnabled true to enable, false to disable.
 *  @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 *  Check whether the SDK is enabled or not as a whole.
 *
 *  @return true if enabled, false otherwise.
 *  @see setEnabled:
 */
+ (BOOL)isEnabled;

/**
 *  Get log level.
 *
 *  @return log level.
 */
+ (SNMLogLevel)logLevel;

/**
 *  Set log level.
 *
 *  @param logLevel the log level.
 */
+ (void)setLogLevel:(SNMLogLevel)logLevel;

/**
 *  Set log level handler.
 *
 *  @param logHandler handler.
 */
+ (void)setLogHandler:(SNMLogHandler)logHandler;

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
 *  @return BOOL if the debugger is attached.
 */
+ (BOOL)isDebuggerAttached;

@end
