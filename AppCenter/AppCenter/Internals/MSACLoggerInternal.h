// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACLogger.h"

FOUNDATION_EXPORT MSACLogHandler const msDefaultLogHandler;

@interface MSACLogger ()

+ (BOOL)isUserDefinedLogLevel;

/*
 * For testing only.
 */
+ (void)setIsUserDefinedLogLevel:(BOOL)isUserDefinedLogLevel;

+ (MSACLogLevel)currentLogLevel;

+ (void)setCurrentLogLevel:(MSACLogLevel)currentLogLevel;

+ (void)setLogHandler:(MSACLogHandler)logHandler;

@end
