// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSACSessionHistoryInfo.h"
#import "MSACSessionTrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSACSessionTracker : NSObject <MSACChannelDelegate>

/**
 * Session tracker delegate.
 */
@property(nonatomic) id<MSACSessionTrackerDelegate> delegate;

/**
 * Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 * Timestamp of the last created log.
 */
@property(nonatomic) NSDate *lastCreatedLogTime;

/**
 * Timestamp of the last time that the app entered foreground.
 */
@property(nonatomic) NSDate *lastEnteredForegroundTime;

/**
 * Timestamp of the last time that the app entered background.
 */
@property(nonatomic) NSDate *lastEnteredBackgroundTime;

/**
 * Automatic session generator.
 */
@property BOOL automaticSessionGeneratorEnabled;

/**
 * Start session tracking.
 */
- (void)start;

/**
 * Stop session tracking.
 */
- (void)stop;

/**
 * Automatic session tracking checking.
 */
- (void)isAutomaticSessionGeneratorEnabled:(BOOL)isEnabled;

/**
 * Start manual session tracking.
 */
- (void)startSession;

/**
 * Stop manual session tracking.
 */
- (void)stopSession;

/**
 * Send start session request.
 */
- (void)sendStartSession;

@end

NS_ASSUME_NONNULL_END
