/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVAConstants.h"

/**
 Class comment: Some Introduction
 */
@interface AVAAvalanche : NSObject

/**
 * Returns the singleton instance of AvalancheHub
 */
+ (id)sharedInstance;

/**
 * Description of method.
 *
 * param features Description of parameter
 */
+ (void)useFeatures:(NSArray<Class> *)features withAppKey:(NSString *)appKey;

/**
 *  Enable/Disable all features
 *
 *  @param isEnabled is enabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 *  Get log level
 *
 *  @return log level
 */
+ (AVALogLevel)logLevel;

/**
 *  Set log level
 *
 *  @param logLevel the log level
 */
+ (void)setLogLevel:(AVALogLevel)logLevel;

/**
 *  Set log level handler
 *
 *  @param logHandler handler
 */
+ (void)setLogHandler:(AVALogHandler)logHandler;

@end
