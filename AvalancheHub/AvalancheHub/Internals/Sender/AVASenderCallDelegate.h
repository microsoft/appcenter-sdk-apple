/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVASenderCall;

@protocol AVASenderCallDelegate <NSObject>

/**
 *  Send call
 *
 *  @param call Call object.
 */
- (void)sendCallAsync:(id<AVASenderCall>)call;

/**
 *  Call completed callback
 *
 *  @param callId call id
 */
- (void)callCompletedWithId:(NSString *)callId;

@end
