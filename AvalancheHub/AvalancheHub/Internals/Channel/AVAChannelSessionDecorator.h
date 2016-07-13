/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVAChannel.h"
#import "AVAChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Channel decorator, adding session and device semantic to the logs.
 */
@interface AVAChannelSessionDecorator
    : NSObject <AVAChannel, AVAChannelDelegate>

/**
 *  Decorated channel.
 */
@property(nonatomic, strong, nullable) id<AVAChannel> channel;

/**
 *  Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 *  Initialize the channel decorator.
 *
 *  @param channel Channel to be decorated.
 *
 *  @return instance of class.
 */
- (instancetype)initWithChannel:(id<AVAChannel>)channel;

@end

NS_ASSUME_NONNULL_END
