/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@protocol SNMSender;

@protocol SNMSenderDelegate <NSObject>

@optional

/**
 *  Triggered after the sender has suspended its state.
 *
 *  @param sender Sender.
 */
- (void)senderDidSuspend:(id<SNMSender>)sender;

/**
 *  Triggered after the sender has resumed its state.
 *
 *  @param sender Sender.
 */
- (void)senderDidResume:(id<SNMSender>)sender;

@end
