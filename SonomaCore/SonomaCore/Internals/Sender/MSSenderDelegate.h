/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@protocol MSSender;

@protocol MSSenderDelegate <NSObject>

@optional

/**
 * Triggered after the sender has suspended its state.
 *
 * @param sender Sender.
 */
- (void)senderDidSuspend:(id<MSSender>)sender;

/**
 * Triggered after the sender has resumed its state.
 *
 * @param sender Sender.
 */
- (void)senderDidResume:(id<MSSender>)sender;

/**
 *  Triggered after the sender has set its enabled state.
 *
 *  @param sender     Sender.
 *  @param isEnabled  A boolean reflecting the sender's enabled state.
 *  @param deleteData A boolean value set to YES if sender's data deletion was requested, NO otherwise.
 */
- (void)sender:(id<MSSender>)sender didSetEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData;

@end
