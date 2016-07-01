/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVASender.h"
#import "AVAChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVAHttpSender : NSObject<AVASender>

@property (nonatomic, weak) id<AVAChannelDelegate> delegate;


/**
 *	BaseURL to which relative paths are appended.
 */
@property (nonatomic, strong, readonly) NSString* baseURL;

@property (nonatomic, strong) dispatch_queue_t senderBatcheQueue;

/**
 *	Request header parameters.
 */
@property (nonatomic, strong) NSDictionary* headerParam;


@end
NS_ASSUME_NONNULL_END