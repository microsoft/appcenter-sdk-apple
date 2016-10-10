/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "SNMChannel.h"

@class SNMLogWithProperties;
@class SNMLog;

@protocol SNMChannelDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each log will be send to the
 * server.
 * @param Instance of SNMChannel.
 * @param log The log to be sent.
 */
- (void)channel:(id<SNMChannel>)channel willSendLog:(id <SNMLog>)log;

@end
