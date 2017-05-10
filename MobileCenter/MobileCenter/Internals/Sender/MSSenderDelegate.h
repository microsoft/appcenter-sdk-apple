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
 * Triggered when sender receives a fatal error.
 *
 * @param sender Sender.
 */
- (void)senderDidReceiveFatalError:(id<MSSender>)sender;

@end
