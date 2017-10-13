#import "MSChannelDefault.h"

/**
 * Private declarations.
 */
@interface MSChannelDefault ()

/**
 * A boolean value set to YES if the channel is enabled or NO otherwise.
 * Enable/disable does resume/suspend the channel as needed under the hood.
 * When a channel is disabled with data deletion it deletes persisted logs and discards incoming logs.
 */
@property(nonatomic) BOOL enabled;

/**
 * A boolean value set to YES if the channel is suspended or NO otherwise.
 * A channel is suspended when it becomes disabled or when its sender becomes suspended itself.
 * A suspended channel doesn't forward logs to the sender.
 * A suspended state doesn't impact the current enabled state.
 */
@property(nonatomic) BOOL suspended;

/**
 * A boolean value set to YES if logs are discarded (not persisted) or NO otherwise.
 * Logs are discarded when the related service is disabled or an unrecoverable error happened.
 */
@property(nonatomic) BOOL discardLogs;

/**
 * A property to hold the observer to get notified once the app goes into the background. It will trigger a call to
 * flush the queue and send events to the backend.
 */
@property(nonatomic, weak, nullable) id appDidEnterBackgroundObserver;

#if !TARGET_OS_OSX

// Properties that are necessary to allow sending events at the time the app is backgrounded. Not needed on macOS.

/**
 * A property to hold the observer to get notified once the app enters the foreground again.
 */
@property(nonatomic, weak, nullable) id appWillEnterForegroundObserver;

/**
 * Identifier for the background task for flushing our queue in case the app is backgrounded. We're not using
 * UIBackgroundTaskIdentifier as it is not available on macOS and it's a typedef for NSUInteger anyway.
 */
@property(nonatomic) NSUInteger backgroundTaskIdentifier;

/**
 * Flag to indicate if the app is in the background. Required to suspend the sender in case there are no logs.
 */
@property(nonatomic) BOOL isInBackground;
#endif

/**
 * Trigger flushing the queue, which will result in logs being sent.
 */
- (void)flushQueue;

/**
 * Method to invalide the background task that sends events and suspend the sender once there is nothing to send.
 */
- (void)stopBackgroundActivity;

@end
