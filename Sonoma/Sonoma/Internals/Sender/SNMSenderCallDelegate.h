/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol SNMSenderCall;

@protocol SNMSenderCallDelegate <NSObject>

/**
 *  Send call.
 *
 *  @param call Call object.
 */
- (void)sendCallAsync:(id<SNMSenderCall>)call;

/**
 *  Call completed callback.
 *
 *  @param callId call id.
 */
- (void)callCompletedWithId:(NSString *)callId;

@end
