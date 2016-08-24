/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAConstants.h"
#import <Foundation/Foundation.h>

/**
 Class comment: Some Introduction
 */
@interface AVAAvalanche : NSObject

/**
 *  Start the SDK
 *
 *  @param features  array of features to be used.
 *  @param appSecret application secret.
 */
+ (void)start:(NSArray<Class> *)features withAppSecret:(NSString *)appSecret;

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
+ (AVALogLevel)logLevel;

/**
 *  Set log level.
 *
 *  @param logLevel the log level.
 */
+ (void)setLogLevel:(AVALogLevel)logLevel;

/**
 *  Set log level handler.
 *
 *  @param logHandler handler.
 */
+ (void)setLogHandler:(AVALogHandler)logHandler;

/**
 * Get unique installation identifier.
 *
 * @return unique installation identifier.
 */
+ (NSUUID *)installId;

@end
