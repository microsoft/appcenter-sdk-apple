#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSDeviceTracker.h"

NS_ASSUME_NONNULL_BEGIN

@class MSHttpSender;
@protocol MSStorage;

/**
 * A channel group which triggers and manages the processing of log items on
 * different channels. All items will be immediately passed to the persistence
 * layer in order to make the queue crash safe. Once a maximum number of items
 * have been enqueued or the internal timer finished running, events will be
 * forwarded to the sender. Furthermore, its responsibility is to tell the
 * persistence layer what to do with a pending batch based on the status code
 * returned by the sender
 */
@interface MSChannelGroupDefault : NSObject <MSChannelGroupProtocol>

/**
 * Collection of channel delegates.
 */
@property(nonatomic) NSHashTable<id<MSChannelDelegate>> *delegates;

/**
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong, nullable) MSHttpSender *sender;

/**
 * A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong) id<MSStorage> storage;

/**
 * A queue which makes adding new items thread safe.
 */
@property(nonatomic, strong) dispatch_queue_t logsDispatchQueue;

/**
 * An array containing all channels that are a part of this channel group.
 */
@property(nonatomic, copy) NSMutableArray *channels;

/**
 * The app secret.
 */
@property(nonatomic, copy) NSString *appSecret;

@end

NS_ASSUME_NONNULL_END
