/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "MSChannel.h"

@class MSLogWithProperties;
@class MSLog;

@protocol MSChannelDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each log will be send to the server.
 * @param Instance of SNMChannel.
 * @param log The log to be sent.
 */
- (void)channel:(id <MSChannel>)channel willSendLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case the SDK was able to send a log.
 * @param Instance of SNMChannel.
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id <MSChannel>)channel didSucceedSendingLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case the SDK was unable to send a log.
 * @param Instance of SNMChannel.
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id <MSChannel>)channel didFailSendingLog:(id <MSLog>)log withError:(NSError *)error;


@end
