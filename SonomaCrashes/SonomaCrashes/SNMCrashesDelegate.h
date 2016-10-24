/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SNMCrashes;
@class SNMErrorReport;
@class SNMErrorAttachment;

@protocol SNMCrashesDelegate <NSObject>

@optional

/**
 * Callback method that will be called before processing errors. Based on the return value,
 * Crashes will send logs to the server or discard/delete logs.
 * @param crashes The instance of SNMCrashes.
 * @param errorReport The errorReport that will be sent.
 */
- (BOOL)crashes:(SNMCrashes *)crashes shouldProcessErrorReport:(SNMErrorReport *)errorReport;

/**
 * Callback method that will get additional information to be attached to a error report before sending.
 * Attachement is an optional so the method can also return nil.
 * @param crashes The instance of SNMCrashes.
 * @param errorReport The errorReport that will be sent.
 */
- (SNMErrorAttachment *)attachmentWithCrashes:(SNMCrashes *)crashes forErrorReport:(SNMErrorReport *)errorReport;

/**
 * Callback method that will be called before each error will be send to the
 * server. Use this callback to display custom UI while crashes are sent to the server.
 * @param crashes The instance of SNMCrashes.
 * @param errorReport The errorReport that will be sent.
 */
- (void)crashes:(SNMCrashes *)crashes willSendErrorReport:(SNMErrorReport *)errorReport;

/**
 * Callback method that will be called in case the SDK was unable to send an error report to the server. Use this method to hide custom
 * @param crashes The instance of SNMCrashes.
 * @param errorReport The errorReport that Sonoma sent.
 */
- (void)crashes:(SNMCrashes *)crashes didSucceedSendingErrorReport:(SNMErrorReport *)errorReport;

/**
 * Callback method that will be called in case the SDK was unable to send an error report to the server.
 * @param crashes The instance of SNMCrashes.
 * @param errorReport The errorReport that Sonoma tried to send.
 * @param error The error that occured.
 */
- (void)crashes:(SNMCrashes *)crashes didFailSendingErrorReport:(SNMErrorReport *)errorReport withError:(NSError *)error;

@end
