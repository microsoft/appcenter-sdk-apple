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

@end
