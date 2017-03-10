#import <Foundation/Foundation.h>

#import "MSChannel.h"
#import "MSChannelConfiguration.h"
#import "MSSender.h"
#import "MSStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChannelDefault : NSObject <MSChannel>

/**
 * Queue used to process logs.
 */
@property(nonatomic, strong) dispatch_queue_t logsDispatchQueue;

/**
 * Hash table of channel delegate.
 */
@property(nonatomic) NSHashTable<id<MSChannelDelegate>> *delegates;

/**
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong) id<MSSender> sender;

/**
 * A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong) id<MSStorage> storage;

/**
 * A timer source which is used to flush the queue after a certain amount of
 * time.
 */
@property(nonatomic, strong) dispatch_source_t timerSource;

/**
 * A counter that keeps tracks of the number of logs added to the queue.
 */
@property(nonatomic, assign) NSUInteger itemsCount;

/**
 * A list used to keep track of batches that have been forwarded to the sender component.
 */
@property(nonatomic, copy) NSMutableArray *pendingBatchIds;

/**
 * A boolean value set to YES if there is at least one available batch from the storage.
 */
@property(nonatomic) BOOL availableBatchFromStorage;

/**
 * A boolean value set to YES if the pending batch queue is full.
 */
@property(nonatomic) BOOL pendingBatchQueueFull;

@end

NS_ASSUME_NONNULL_END
