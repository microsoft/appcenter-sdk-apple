#import <Foundation/Foundation.h>
#import "MSChannel.h"
#import "MSDeviceTracker.h"
#import "MSEnable.h"
#import "MSLogManager.h"
#import "MSLogManagerDelegate.h"
#import "MSSender.h"
#import "MSStorage.h"

NS_ASSUME_NONNULL_BEGIN

@class MSHttpSender;

/**
 * A log manager which triggers and manages the processing of log items on
 * different channels. All items will be immediately passed to the persistence
 * layer in order to make the queue crash safe. Once a maximum number of items
 * have been enqueued or the internal timer finished running, events will be
 * forwarded to the sender. Furthermore, its responsibility is to tell the
 * persistence layer what to do with a pending batch based on the status code
 * returned by the sender
 */
@interface MSLogManagerDefault : NSObject <MSLogManager>

/**
 * Initializes a new `MSLogManager` instance.
 *
 * @param appSecret A unique and secret key used to identify the application.
 * @param installId A unique installation identifier.
 * @param logUrl A base URL to use for backend communication.
 *
 * @return A new `MSLogManager` instance.
 */
- (instancetype)initWithAppSecret:(NSString *)appSecret installId:(NSUUID *)installId logUrl:(NSString *)logUrl;

/**
 * A boolean value set to YES if this instance is enabled or NO otherwise.
 */
@property BOOL enabled;

/**
 * Hash table of log manager delegate.
 */
@property(nonatomic) NSHashTable<id<MSLogManagerDelegate>> *delegates;

/**
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong) MSHttpSender *sender;

/**
 * A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong) id<MSStorage> storage;

/**
 * A queue which makes adding new items thread safe.
 */
@property(nonatomic, strong) dispatch_queue_t logsDispatchQueue;

/**
 * A dictionary containing priority keys and their channel.
 */
@property(nonatomic, copy) NSMutableDictionary<NSString *, id<MSChannel>> *channels;

@end

NS_ASSUME_NONNULL_END
