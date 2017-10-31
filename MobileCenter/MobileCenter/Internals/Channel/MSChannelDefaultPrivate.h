#import "MSChannelDefault.h"

NS_ASSUME_NONNULL_BEGIN

static const MSDoneFlushingCompletionBlock kMSEmptyDoneFlushingCompletion = ^(){};

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

#if !TARGET_OS_OSX

// Properties that are necessary to allow sending events at the time the app is backgrounded. Not needed on macOS.

/**
 * Completion block executed when done flushing logs.
 */
@property(nonatomic, nullable) MSDoneFlushingCompletionBlock doneFlushingCompletion;

#endif

/**
 * Trigger flushing the queue, which will result in logs being sent.
 */
- (void)flushQueue;

@end

NS_ASSUME_NONNULL_END

