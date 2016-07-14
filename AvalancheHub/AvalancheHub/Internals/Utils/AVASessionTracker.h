/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannel.h"
#import "AVASessionTrackerDelegate.h"
#import <Foundation/Foundation.h>

@interface AVASessionTracker : NSObject

@property(nonatomic) id<AVASessionTrackerDelegate> delegate;

/**
 *  Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 *  Timestamp of the last time that the app entered foreground
 */
@property(nonatomic) NSDate *lastEnteredForegroundTime;

/**
 *  Timestamp of the last time that the app entered background
 */
@property(nonatomic) NSDate *lastEnteredBackgroundTime;

/**
 *  Channel object
 */
@property(nonatomic) id<AVAChannel> channel;

/**
 *  Initializer
 *
 *  @param channel instance of channel
 *
 *  @return Instance of the class
 */
- (instancetype)initWithChannel:(id<AVAChannel>)channel;

/**
 *  Start session tracking
 */
- (void)start;

/**
 *  Stop session tracking
 */
- (void)stop;

/**
 *  Return the current session ID and renew the session if required
 *
 *  @return session id
 */
- (NSString *)getSessionId;

@end
