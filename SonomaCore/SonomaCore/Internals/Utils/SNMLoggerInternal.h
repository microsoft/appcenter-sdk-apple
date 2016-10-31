/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMLogger.h"

FOUNDATION_EXPORT SNMLogHandler const defaultLogHandler;

@interface SNMLogger ()

+ (BOOL)isUserDefinedLogLevel;

/*
 * For testing only.
 */
+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel;

+ (SNMLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(SNMLogLevel)currentLogLevel;
+ (void)setLogHandler:(SNMLogHandler)logHandler;

@end
