#import "MSChannelUnitDefault.h"
#import "MSAbstractLogInternal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSChannelDelegate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSDeviceTracker.h"
#import "MSIngestionProtocol.h"
#import "MSStorage.h"

@implementation MSChannelUnitDefault

@synthesize configuration = _configuration;
@synthesize logsDispatchQueue = _logsDispatchQueue;

#pragma mark - Initialization

- (instancetype)init {
  if ((self = [super init])) {
    _itemsCount = 0;
    _pendingBatchIds = [NSMutableArray new];
    _pendingBatchQueueFull = NO;
    _availableBatchFromStorage = NO;
    _enabled = YES;
    _suspended = NO;
    _discardLogs = NO;
    _delegates = [NSHashTable weakObjectsHashTable];
  }
  return self;
}

- (instancetype)initWithIngestion:(nullable id<MSIngestionProtocol>)ingestion
                          storage:(id<MSStorage>)storage
                    configuration:(MSChannelUnitConfiguration *)configuration
                logsDispatchQueue:(dispatch_queue_t)logsDispatchQueue {
  if ((self = [self init])) {
    _ingestion = ingestion;
    _storage = storage;
    _configuration = configuration;
    _logsDispatchQueue = logsDispatchQueue;

    // Register as ingestion delegate.
    [_ingestion addDelegate:self];

    // Match ingestion's current status, if one is passed.
    if (_ingestion && _ingestion.suspended) {
      [self suspend];
    }
  }
  return self;
}

- (void)setAppSecret:(NSString *)appSecret {
  _appSecret = appSecret;
}

#pragma mark - MSChannelDelegate

- (void)addDelegate:(id<MSChannelDelegate>)delegate {
  dispatch_async(self.logsDispatchQueue, ^{
    @synchronized(self.delegates) {
      [self.delegates addObject:delegate];
    }
  });
}

- (void)removeDelegate:(id<MSChannelDelegate>)delegate {
  dispatch_async(self.logsDispatchQueue, ^{
    @synchronized(self.delegates) {
      [self.delegates removeObject:delegate];
    }
  });
}

#pragma mark - MSIngestionDelegate

- (void)ingestionDidSuspend:(__unused id<MSIngestionProtocol>)ingestion {
  [self suspend];
}

- (void)ingestionDidResume:(__unused id<MSIngestionProtocol>)ingestion {
  [self resume];
}

- (void)ingestionDidReceiveFatalError:
    (__unused id<MSIngestionProtocol>)ingestion {

  // Disable and delete data on fatal errors.
  [self setEnabled:NO andDeleteDataOnDisabled:YES];
}

#pragma mark - Managing queue

- (void)enqueueItem:(id<MSLog>)item {
  /*
   * Set common log info.
   * Only add timestamp and device info in case the log doesn't have one. In
   * case the log is restored after a crash or for crashes, we don't want the
   * timestamp and the device information to be updated but want the old one
   * preserved.
   */
  if (item && !item.timestamp) {
    item.timestamp = [NSDate date];
  }
  if (item && !item.device) {
    item.device = [[MSDeviceTracker sharedInstance] device];
  }
  if (!item || ![item isValid]) {
    MSLogWarning([MSAppCenter logTag], @"Log is not valid.");
    return;
  }

  // Additional preparations for the log. Used to specify the session id and
  // distribution group id.
  [self enumerateDelegatesForSelector:@selector(channel:prepareLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:self prepareLog:item];
                            }];

  // Internal ID to keep track of logs between modules.
  NSString *internalLogId = MS_UUID_STRING;

  // Notify delegate about enqueuing as fast as possible on the current thread.
  [self enumerateDelegatesForSelector:@selector
        (channel:didPrepareLog:withInternalId:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:self
                                   didPrepareLog:item
                                  withInternalId:internalLogId];
                            }];

  // Return fast in case our item is empty or we are discarding logs right now.
  dispatch_async(self.logsDispatchQueue, ^{

    // Check if the log should be filtered out. If so, don't enqueue it.
    __block BOOL shouldFilter = NO;
    [self enumerateDelegatesForSelector:@selector(channelUnit:shouldFilterLog:)
                              withBlock:^(id<MSChannelDelegate> delegate) {
                                shouldFilter =
                                    shouldFilter || [delegate channelUnit:self
                                                          shouldFilterLog:item];
                              }];

    // If ingestion is nil, there is nothing to do at this point.
    if (shouldFilter) {
      MSLogDebug([MSAppCenter logTag],
                 @"Log of type '%@' was filtered out by delegate(s)",
                 item.type);
      [self enumerateDelegatesForSelector:@selector
            (channel:didCompleteEnqueueingLog:withInternalId:)
                                withBlock:^(id<MSChannelDelegate> delegate) {
                                  [delegate channel:self
                                      didCompleteEnqueueingLog:item
                                                withInternalId:internalLogId];
                                }];
      return;
    }
    if (!self.appSecret && !item.transmissionTargetTokens) {
      MSLogDebug([MSAppCenter logTag],
                 @"Log of type '%@' was not filtered out by delegate(s) but no "
                 @"app secret was "
                 @"provided. Not persisting/sending the log.",
                 item.type);
      [self enumerateDelegatesForSelector:@selector
            (channel:didCompleteEnqueueingLog:withInternalId:)
                                withBlock:^(id<MSChannelDelegate> delegate) {
                                  [delegate channel:self
                                      didCompleteEnqueueingLog:item
                                                withInternalId:internalLogId];
                                }];
      return;
    }
    if (self.discardLogs) {
      MSLogWarning(
          [MSAppCenter logTag],
          @"Channel disabled in log discarding mode, discard this log.");
      NSError *error = [NSError
          errorWithDomain:kMSACErrorDomain
                     code:kMSACConnectionSuspendedErrorCode
                 userInfo:@{
                   NSLocalizedDescriptionKey : kMSACConnectionSuspendedErrorDesc
                 }];
      [self notifyFailureBeforeSendingForItem:item withError:error];
      [self enumerateDelegatesForSelector:@selector
            (channel:didCompleteEnqueueingLog:withInternalId:)
                                withBlock:^(id<MSChannelDelegate> delegate) {
                                  [delegate channel:self
                                      didCompleteEnqueueingLog:item
                                                withInternalId:internalLogId];
                                }];
      return;
    }

    // Save the log first.
    MSLogDebug([MSAppCenter logTag], @"Saving log, type: %@.", item.type);
    [self.storage saveLog:item withGroupId:self.configuration.groupId];
    self.itemsCount += 1;
    [self enumerateDelegatesForSelector:@selector
          (channel:didCompleteEnqueueingLog:withInternalId:)
                              withBlock:^(id<MSChannelDelegate> delegate) {
                                [delegate channel:self
                                    didCompleteEnqueueingLog:item
                                              withInternalId:internalLogId];
                              }];

    // Flush now if current batch is full or delay to later.
    if (self.itemsCount >= self.configuration.batchSizeLimit) {
      [self flushQueue];
    } else if (self.itemsCount == 1) {

      // Don't delay if channel is suspended but stack logs until current batch
      // max out.
      if (!self.suspended) {
        [self startTimer];
      }
    }
  });
}

- (void)flushQueue {

  // Nothing to flush if there is no ingestion.
  if (!self.ingestion) {
    return;
  }

  // Don't flush while disabled.
  if (!self.enabled) {
    return;
  }

  // Cancel any timer.
  [self resetTimer];

  // Don't flush while suspended or if pending bach queue is full.
  if (self.suspended || self.pendingBatchQueueFull) {

    // Still close the current batch it will be flushed later.
    if (self.itemsCount >= self.configuration.batchSizeLimit) {

      // That batch becomes available.
      self.availableBatchFromStorage = YES;
      self.itemsCount = 0;
    }
    return;
  }

  // Reset item count and load data from the storage.
  self.itemsCount = 0;
  self.availableBatchFromStorage = [self.storage
      loadLogsWithGroupId:self.configuration.groupId
                    limit:self.configuration.batchSizeLimit
           withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                            NSString *batchId) {

             // Logs may be deleted from storage before this flush.
             if (batchId.length > 0) {
               [self.pendingBatchIds addObject:batchId];
               if (self.pendingBatchIds.count >=
                   self.configuration.pendingBatchesLimit) {
                 self.pendingBatchQueueFull = YES;
               }
               MSLogContainer *container =
                   [[MSLogContainer alloc] initWithBatchId:batchId
                                                   andLogs:logArray];

               // Optimization. If the current log level is greater than
               // MSLogLevelDebug, we can skip it.
               if ([MSAppCenter logLevel] <= MSLogLevelDebug) {
                 NSUInteger count = [container.logs count];
                 for (NSUInteger i = 0; i < count; i++) {
                   MSLogDebug([MSAppCenter logTag],
                              @"Sending %tu/%tu log, group Id: %@, batch Id: "
                              @"%@, session Id: %@, payload:\n%@",
                              (i + 1), count, self.configuration.groupId,
                              batchId, container.logs[i].sid,
                              [(MSAbstractLog *)container.logs[i]
                                  serializeLogWithPrettyPrinting:YES]);
                 }
               }

               // Notify delegates.
               [self
                   enumerateDelegatesForSelector:@selector(channel:willSendLog:)
                                       withBlock:^(
                                           id<MSChannelDelegate> delegate) {
                                         for (id<MSLog> aLog in logArray) {
                                           [delegate channel:self
                                                 willSendLog:aLog];
                                         }
                                       }];

               // Forward logs to the ingestion.
               [self.ingestion
                           sendAsync:container
                           appSecret:self.appSecret
                   completionHandler:^(
                       NSString *ingestionBatchId, NSUInteger statusCode,
                       __attribute__((unused)) NSData *data, NSError *error) {
                     dispatch_async(self.logsDispatchQueue, ^{
                       if ([self.pendingBatchIds
                               containsObject:ingestionBatchId]) {

                         // Success.
                         if (statusCode == MSHTTPCodesNo200OK) {
                           MSLogDebug([MSAppCenter logTag],
                                      @"Log(s) sent with success, batch Id:%@.",
                                      ingestionBatchId);

                           // Notify delegates.
                           [self
                               enumerateDelegatesForSelector:@selector
                               (channel:didSucceedSendingLog:)
                                                   withBlock:^(
                                                       id<MSChannelDelegate>
                                                           delegate) {
                                                     for (id<MSLog> aLog in
                                                              logArray) {
                                                       [delegate channel:self
                                                           didSucceedSendingLog:
                                                               aLog];
                                                     }
                                                   }];

                           // Remove from pending logs and storage.
                           [self.pendingBatchIds removeObject:ingestionBatchId];
                           [self.storage
                               deleteLogsWithBatchId:ingestionBatchId
                                             groupId:self.configuration
                                                         .groupId];

                           // Try to flush again if batch queue is not full
                           // anymore.
                           if (self.pendingBatchQueueFull &&
                               self.pendingBatchIds.count <
                                   self.configuration.pendingBatchesLimit) {
                             self.pendingBatchQueueFull = NO;
                             if (self.availableBatchFromStorage) {
                               [self flushQueue];
                             }
                           }
                         }

                         // Failure.
                         else {
                           MSLogError([MSAppCenter logTag],
                                      @"Log(s) sent with failure, batch Id:%@, "
                                      @"status code:%tu",
                                      ingestionBatchId, statusCode);

                           // Notify delegates.
                           [self enumerateDelegatesForSelector:@selector
                                 (channel:didFailSendingLog:withError:)
                                                     withBlock:^(
                                                         id<MSChannelDelegate>
                                                             delegate) {
                                                       for (id<MSLog> aLog in
                                                                logArray) {
                                                         [delegate channel:self
                                                             didFailSendingLog:
                                                                 aLog
                                                                     withError:
                                                                         error];
                                                       }
                                                     }];

                           // Remove from pending logs.
                           [self.pendingBatchIds removeObject:ingestionBatchId];
                           [self.storage
                               deleteLogsWithBatchId:ingestionBatchId
                                             groupId:self.configuration
                                                         .groupId];

                           // Update pending batch queue state.
                           if (self.pendingBatchQueueFull &&
                               self.pendingBatchIds.count <
                                   self.configuration.pendingBatchesLimit) {
                             self.pendingBatchQueueFull = NO;
                           }
                         }
                       } else
                         MSLogWarning([MSAppCenter logTag],
                                      @"Batch Id %@ not expected, ignore.",
                                      ingestionBatchId);
                     });
                   }];
             }
           }];

  // Flush again if there is another batch to send.
  if (self.availableBatchFromStorage && !self.pendingBatchQueueFull) {
    [self flushQueue];
  }
}

#pragma mark - Timer

- (void)startTimer {

  // Don't start timer while disabled.
  if (!self.enabled) {
    return;
  }

  // Cancel any timer.
  [self resetTimer];

  // Create new timer.
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                            self.logsDispatchQueue);

  /**
   * Cast (NSEC_PER_SEC * self.configuration.flushInterval) to (int64_t) silence
   * warning. The compiler otherwise complains that we're using a float param
   * (flushInterval) and implicitly downcast to int64_t.
   */
  dispatch_source_set_timer(
      self.timerSource,
      dispatch_walltime(
          NULL, (int64_t)(NSEC_PER_SEC * self.configuration.flushInterval)),
      1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.timerSource, ^{
    typeof(self) strongSelf = weakSelf;

    // Flush the queue as needed.
    if (strongSelf) {
      if (strongSelf.itemsCount > 0) {
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
  }
}

#pragma mark - Life cycle

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  dispatch_async(self.logsDispatchQueue, ^{
    if (self.enabled != isEnabled) {
      self.enabled = isEnabled;
      if (isEnabled) {
        if (!self.ingestion.suspended) {
          [self resume];
        }
      } else {
        [self suspend];
      }
    }

    // Even if it's already disabled we might also want to delete logs this
    // time.
    if (!isEnabled && deleteData) {
      MSLogDebug([MSAppCenter logTag], @"Delete all logs for group Id %@",
                 self.configuration.groupId);
      NSError *error = [NSError
          errorWithDomain:kMSACErrorDomain
                     code:kMSACConnectionSuspendedErrorCode
                 userInfo:@{
                   NSLocalizedDescriptionKey : kMSACConnectionSuspendedErrorDesc
                 }];
      [self deleteAllLogsWithErrorSync:error];

      // Reset states.
      self.itemsCount = 0;
      self.availableBatchFromStorage = NO;
      self.pendingBatchQueueFull = NO;

      // Prevent further logs from being persisted.
      self.discardLogs = YES;
    } else {

      // Allow logs to be persisted.
      self.discardLogs = NO;
    }

    // Notify delegates.
    [self enumerateDelegatesForSelector:@selector
          (channel:didSetEnabled:andDeleteDataOnDisabled:)
                              withBlock:^(id<MSChannelDelegate> delegate) {
                                [delegate channel:self
                                              didSetEnabled:isEnabled
                                    andDeleteDataOnDisabled:deleteData];
                              }];
  });
}

- (void)suspend {
  if (!self.suspended) {
    MSLogDebug([MSAppCenter logTag], @"Suspend channel for group Id %@.",
               self.configuration.groupId);
    self.suspended = YES;
    [self resetTimer];
  }
}

- (void)resume {
  if (self.suspended && self.enabled) {
    MSLogDebug([MSAppCenter logTag], @"Resume channel for group Id %@.",
               self.configuration.groupId);
    self.suspended = NO;
    [self flushQueue];
  }
}

#pragma mark - Storage

- (void)deleteAllLogsWithError:(NSError *)error {
  dispatch_async(self.logsDispatchQueue, ^{
    [self deleteAllLogsWithErrorSync:error];
  });
}

- (void)deleteAllLogsWithErrorSync:(NSError *)error {
  NSArray<id<MSLog>> *deletedLogs;

  // Delete pending batches first.
  for (NSString *batchId in self.pendingBatchIds) {
    [self.storage deleteLogsWithBatchId:batchId
                                groupId:self.configuration.groupId];
  }

  // Delete remaining logs.
  deletedLogs = [self.storage deleteLogsWithGroupId:self.configuration.groupId];

  // Notify failure of remaining logs.
  for (id<MSLog> log in deletedLogs) {
    [self notifyFailureBeforeSendingForItem:log withError:error];
  }
}

#pragma mark - Helper

- (void)enumerateDelegatesForSelector:(SEL)selector
                            withBlock:(void (^)(id<MSChannelDelegate> delegate))
                                          block {
  @synchronized(self.delegates) {
    for (id<MSChannelDelegate> delegate in self.delegates) {
      if (delegate && [delegate respondsToSelector:selector]) {
        block(delegate);
      }
    }
  }
}

- (void)notifyFailureBeforeSendingForItem:(id<MSLog>)item
                                withError:(NSError *)error {
  @synchronized(self.delegates) {
    for (id<MSChannelDelegate> delegate in self.delegates) {

      // Call willSendLog before didFailSendingLog
      if (delegate &&
          [delegate respondsToSelector:@selector(channel:willSendLog:)])
        [delegate channel:self willSendLog:item];

      // Call didFailSendingLog
      if (delegate && [delegate respondsToSelector:@selector
                                (channel:didFailSendingLog:withError:)])
        [delegate channel:self didFailSendingLog:item withError:error];
    }
  }
}

@end
