/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionTrackerDelegate.h"
#import <Foundation/Foundation.h>

@interface AVASessionTracker : NSObject

@property(nonatomic) id<AVASessionTrackerDelegate> delegate;

/**
 * Current session id
 */
@property(nonatomic, readonly) NSString *sessionId;

/**
 *  Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 * Timestamp of the last created log
 */
@property(nonatomic) NSDate *lastCreatedLogTime;

/**
 *  Timestamp of the last time that the app entered foreground
 */
@property(nonatomic) NSDate *lastEnteredForegroundTime;

/**
 *  Timestamp of the last time that the app entered background
 */
@property(nonatomic) NSDate *lastEnteredBackgroundTime;

/**
 *  Start session tracking
 */
- (void)start;

/**
 *  Stop session tracking
 */
- (void)stop;

@end
