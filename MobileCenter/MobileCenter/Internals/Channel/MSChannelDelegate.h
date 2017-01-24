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
 * @param Instance of MSChannel.
 * @param log The log to be sent.
 */
- (void)channel:(id <MSChannel>)channel willSendLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case the SDK was able to send a log.
 * @param Instance of MSChannel.
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id <MSChannel>)channel didSucceedSendingLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case the SDK was unable to send a log.
 * @param channel Instance of MSChannel.
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id <MSChannel>)channel didFailSendingLog:(id <MSLog>)log withError:(NSError *)error;

/**
 * Callback method that will be called in case a log was enqueued successfully.
 * For now, there is no callback in case a log was not enqueued successfully.
 *
 * @param channel Instance of MSChannel.
 * @param log The log that was inqueued.
 */
- (void)channel:(id <MSChannel>)channel didEnqueueLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case a log was saved to disk successfully.
 * @param channel Instance of MSChannel.
 * @param log The log that was persisted.
 */
- (void)channel:(id <MSChannel>)channel didSucceedSavingLog:(id <MSLog>)log;

/**
 * Callback method that will be called in case a log could not be saved to disk successfully.
 * @param channel Instance of MSChannel.
 * @param log The log that could not be persisted.
 */
- (void)channel:(id <MSChannel>)channel didFailSavingLog:(id <MSLog>)log;

@end
