/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMChannelDefault.h"
#import "SNMSonomaInternal.h"

/**
 * Private declarations.
 */
@interface SNMChannelDefault ()

/**
 * A boolean value set to YES if the channel is enabled or NO otherwise.
 * Enable/disable does resume/suspend the channel as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * A boolean value set to YES if the channel is suspended or NO otherwise.
 * A channel is suspended when it becomes disabled or when its sender becomes suspended itself.
 * A suspended channel still persists logs but doesn't forward them to the sender.
 * A suspended state doesn't impact the current enabled state.
 */
@property(nonatomic) BOOL suspended;

@end

@implementation SNMChannelDefault

@synthesize configuration = _configuration;

#pragma mark - Initialization

- (instancetype)init {
  if (self = [super init]) {
    _itemsCount = 0;
    _pendingBatchIds = [NSMutableArray new];
    _pendingBatchQueueFull = NO;
    _availableBatchFromStorage = NO;
    _enabled = YES;

    _delegates = [NSMutableArray<id <SNMChannelDelegate>> new];
  }
  return self;
}

- (instancetype)initWithSender:(id <SNMSender>)sender
                       storage:(id <SNMStorage>)storage
                 configuration:(SNMChannelConfiguration *)configuration
                 callbackQueue:(dispatch_queue_t)callbackQueue {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
    _configuration = configuration;
    _callbackQueue = callbackQueue;

    // Register as sender delegate.
    [_sender addDelegate:self];
  }
  return self;
}

#pragma mark - SNMChannelDelegate

- (void)addDelegate:(id <SNMChannelDelegate>)delegate {
  // Check if delegate is not already added.
  if (![self.delegates containsObject:delegate])
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id <SNMChannelDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - Managing queue

- (void)enqueueItem:(id <SNMLog>)item {
  [self enqueueItem:item withCompletion:nil];
}

- (void)enqueueItem:(id <SNMLog>)item withCompletion:(enqueueCompletionBlock)completion {
  if (!item) {
    SNMLogWarning([SNMSonoma getLoggerTag], @"TelemetryItem was nil.");
    return;
  }

  // Save the log first.
  [self.storage saveLog:item withStorageKey:self.configuration.name];
  _itemsCount += 1;
  if (completion)
    completion(YES);

  // Flush now if current batch is full or delay to later.
  if (self.itemsCount >= self.configuration.batchSizeLimit) {
    [self flushQueue];
  } else if (self.itemsCount == 1) {

    // Don't delay if channel is suspended but stack logs until current batch max out.
    if (!self.suspended) {
      [self startTimer];
    }
  }
}

- (void)flushQueue {

  // Cancel any timer.
  [self resetTimer];

  // Don't flush while suspended or if pending bach queue is full.
  if (self.suspended || self.pendingBatchQueueFull) {

    // Still close the current batch it will be flushed later.
    if (self.itemsCount >= self.configuration.batchSizeLimit) {
      [self.storage closeBatchWithStorageKey:self.configuration.name];

      // That batch becomes available.
      self.availableBatchFromStorage = YES;
      self.itemsCount = 0;
    }
    return;
  }

  // Reset item count and load data from the storage.
  self.itemsCount = 0;
  self.availableBatchFromStorage = [self.storage
      loadLogsForStorageKey:self.configuration.name
             withCompletion:^(BOOL succeeded, NSArray <SNMLog> *_Nullable logArray, NSString *_Nullable batchId) {

               // Logs may be deleted from storage before this flush.
               if (succeeded) {
                 [self.pendingBatchIds addObject:batchId];
                 if (self.pendingBatchIds.count >= self.configuration.pendingBatchesLimit) {
                   self.pendingBatchQueueFull = YES;
                 }
                 SNMLogContainer *container = [[SNMLogContainer alloc] initWithBatchId:batchId andLogs:logArray];
                 SNMLogInfo([SNMSonoma getLoggerTag], @"Sending log %@", [container serializeLogWithPrettyPrinting:YES]);

                 // Notify delegates.
                 [self enumerateDelgatesForSelector:@selector(channel:willSendLog:) withBlock:^(id <SNMChannelDelegate> delegate) {
                   for (id <SNMLog> aLog in logArray) {
                     [delegate channel:self willSendLog:aLog];
                   }
                 }];

                 __block NSArray <SNMLog> *_Nullable logs = [logArray copy];

                 // Forward logs to the sender.
                 [self.sender sendAsync:container
                          callbackQueue:self.callbackQueue
                      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {
                        SNMLogInfo([SNMSonoma getLoggerTag], @"HTTP response received with the status code:%lu", (unsigned long) statusCode);

                        if (statusCode != 200) {
                          [self enumerateDelgatesForSelector:@selector(channel:didFailSendingLog:withError:) withBlock:^(
                              id <SNMChannelDelegate> delegate) {
                            for (id <SNMLog> aLog in logs) {
                              [delegate channel:self didFailSendingLog:aLog withError:error];
                            }
                          }];
                        } else {
                          [self enumerateDelgatesForSelector:@selector(channel:didSucceedSendingLog:) withBlock:^(id <SNMChannelDelegate> delegate) {
                            for (id <SNMLog> aLog in logs) {
                              [delegate channel:self didSucceedSendingLog:aLog];
                            }
                          }];
                        }

                        // Remove from pending logs and storage.
                        [self.pendingBatchIds removeObject:batchId];
                        [self.storage deleteLogsForId:batchId withStorageKey:self.configuration.name];

                        // Try to flush again if batch queue is not full anymore.
                        if (self.pendingBatchQueueFull &&
                            self.pendingBatchIds.count < self.configuration.pendingBatchesLimit) {
                          self.pendingBatchQueueFull = NO;
                          if (self.availableBatchFromStorage) {
                            [self flushQueue];
                          }
                        }
                      }];
               }
             }];

  // Flush again if there is another batch to send.
  if (self.availableBatchFromStorage && !self.pendingBatchQueueFull) {
    [self flushQueue];
  }
}

- (void)enumerateDelgatesForSelector:(SEL)selector withBlock:(void (^)(id <SNMChannelDelegate> delegate))block {
  for (id <SNMChannelDelegate> delegate in self.delegates) {
    if (delegate && [delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

#pragma mark - Timer

- (void)startTimer {
  [self resetTimer];

  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.callbackQueue);
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, NSEC_PER_SEC * self.configuration.flushInterval),
                            1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.timerSource, ^{
    typeof(self) strongSelf = weakSelf;

    // Flush the queue as needed.
    if (strongSelf) {
      if (strongSelf->_itemsCount > 0) {
        [strongSelf flushQueue];
      }
      [strongSelf resetTimer];
    }
  });
  dispatch_resume(self.timerSource);
}

- (void)resetTimer {
  if (self.timerSource) {
    dispatch_source_cancel(self.timerSource);
    self.timerSource = nil;
  }
}

#pragma mark - Life cycle

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  self.enabled = isEnabled;
  if (isEnabled) {
    [self resume];
    [self.sender addDelegate:self];
  } else {
    [self.sender removeDelegate:self];
    [self suspend];
    if (deleteData) {
      [self deleteAllLogs];

      // Reset states.
      self.itemsCount = 0;
      self.availableBatchFromStorage = NO;
      self.pendingBatchQueueFull = NO;
    }
  }
}

- (void)suspend {
  if (!self.suspended) {
    self.suspended = YES;
    [self resetTimer];
  }
}

- (void)resume {
  if (self.suspended && self.enabled) {
    self.suspended = NO;
    [self flushQueue];
  }
}

#pragma mark - Storage

- (void)deleteAllLogs {
  [self.pendingBatchIds removeAllObjects];
  [self.storage deleteLogsForStorageKey:self.configuration.name];
}

#pragma mark - SNMSenderDelegate

- (void)senderDidSuspend:(id <SNMSender>)sender {
  [self suspend];
}

- (void)senderDidResume:(id <SNMSender>)sender {
  [self resume];
}

@end
