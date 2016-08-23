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
 * Returns the singleton instance of AvalancheHub.
 */
+ (instancetype)sharedInstance;

/**
 *  Start the sdk
 *
 *  @param appSecret application secret.
 *  @param features  array of features to be used.
 */
+ (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features;

/**
 *  Enable/Disable all features.
 *
 *  @param isEnabled is enabled.
 */
+ (void)setEnabled:(BOOL)isEnabled;

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
