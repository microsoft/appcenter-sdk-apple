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
 * Description of method.
 *
 * param features Description of parameter
 */
+ (void)useFeatures:(NSArray<Class> *)features;

+ (void)useFeatures:(NSArray<Class> *)features identifier:(NSString *)identifier;

+ (AVALogLevel)logLevel;
+ (void)setLogLevel:(AVALogLevel)logLevel;
+ (void)setLogHandler:(AVALogHandler)logHandler;

@end
