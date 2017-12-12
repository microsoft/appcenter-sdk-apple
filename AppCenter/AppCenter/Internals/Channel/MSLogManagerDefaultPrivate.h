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

@end

NS_ASSUME_NONNULL_END
