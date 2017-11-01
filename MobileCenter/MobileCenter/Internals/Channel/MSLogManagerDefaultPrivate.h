#import <Foundation/Foundation.h>

#import "MSChannel.h"
#import "MSDeviceTracker.h"
#import "MSEnable.h"
#import "MSLogManagerDelegate.h"
#import "MSSender.h"
#import "MSStorage.h"

NS_ASSUME_NONNULL_BEGIN

static short *const kMSStorageMaxCapacity = 300;

@class MSHttpSender;

@interface MSLogManagerDefault ()

/**
 * Initializes a new `MSLogManager` instance.
 *
 * @param sender An HTTP sender instance that is used to send batches of log items to
 * the backend.
 * @param storage A storage instance to store and read enqueued log items.
 *
 * @return A new `MSLogManager` instance.
 */
- (instancetype)initWithSender:(MSHttpSender *)sender storage:(id<MSStorage>)storage;

/**
 * Identifier for the background task for flushing our queue in case the app is backgrounded. We're not using
 * UIBackgroundTaskIdentifier as it is not available on macOS and it's a typedef for NSUInteger anyway.
 */
@property(nonatomic) NSUInteger backgroundTaskIdentifier;

/**
 * Lock token for background task synchronization.
 */
@property(nonatomic, nonnull) NSObject *backgroundTaskLockToken;

/**
 * A property to hold the observer to get notified once the app enters the foreground again.
 */
@property(nonatomic, weak, nullable) id appWillEnterForegroundObserver;

/**
 * A property to hold the observer to get notified once the app goes into the background. It will trigger a call to
 * flush the queue and send events to the backend.
 */
@property(nonatomic, weak, nullable) id appDidEnterBackgroundObserver;

/**
 * Keep track of the number of channels that stopped flushing.
 */
@property(nonatomic) ushort flushedChannelsCount;

@end

NS_ASSUME_NONNULL_END
