/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SNMCrashes;
@class SNMErrorReport;

@protocol SNMCrashesDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each error will be send to the
 * server.
 * @param instance of SNMCrashes.
 */
- (void)crashes:(SNMCrashes *)crashes willSendErrorReport:(SNMErrorReport *)errorReport;

@end
