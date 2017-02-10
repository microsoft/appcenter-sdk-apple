/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class MSSenderCall;

@protocol MSSenderCallDelegate <NSObject>

/**
 *  Send call.
 *
 *  @param call Call object.
 */
- (void)sendCallAsync:(MSSenderCall *)call;

/**
 *  Call completed callback.
 *
 *  @param callId call id.
 */
- (void)callCompletedWithId:(NSString *)callId;

@end
