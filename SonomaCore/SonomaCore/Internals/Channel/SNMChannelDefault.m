/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMChannelDefault.h"
#import "SonomaCore+Internal.h"
#import "SNMChannelDelegate.h"

@implementation SNMChannelDefault

@synthesize configuration = _configuration;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _itemsCount = 0;
    _pendingLogsIds = [NSMutableArray new];
    _delegates = [NSMutableArray<id<SNMChannelDelegate>> new];
  }
  return self;
}

- (instancetype)initWithSender:(id<SNMSender>)sender
                       storage:(id<SNMStorage>)storage
                 configuration:(SNMChannelConfiguration *)configuration
                 callbackQueue:(dispatch_queue_t)callbackQueue {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
    _configuration = configuration;
    _callbackQueue = callbackQueue;
  }
  return self;
}

#pragma mark - SNMChannelDelegate

- (void)addDelegate:(id<SNMChannelDelegate>)delegate {
  // Check if delegate is not already added.
  if (![self.delegates containsObject:delegate])
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SNMChannelDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - Managing queue

- (void)enqueueItem:(id<SNMLog>)item {
  [self enqueueItem:item withCompletion:nil];
}

- (void)enqueueItem:(id<SNMLog>)item withCompletion:(enqueueCompletionBlock)completion {
  if (!item) {
    SNMLogWarning(@"WARNING: TelemetryItem was nil.");
    return;
  }
  _itemsCount += 1;
  [self.storage saveLog:item withStorageKey:self.configuration.name];

  if (completion)
    completion(YES);

  if (self.itemsCount >= self.configuration.batchSizeLimit) {
    [self flushQueue];
  } else if (self.itemsCount == 1) {
    [self startTimer];
  }
}

- (void)flushQueue {
  _itemsCount = 0;
  [self.storage
      loadLogsForStorageKey:self.configuration.name
             withCompletion:^(BOOL succeeded, NSArray<SNMLog> *_Nullable logArray, NSString *_Nullable batchId) {

               // Logs may be deleted from storage before this flush.
               if (succeeded) {
                 if (self.pendingLogsIds.count < self.configuration.pendingBatchesLimit) {
                   [self.pendingLogsIds addObject:batchId];
                   
                   // Notify delegates.
                   for (id<SNMChannelDelegate> aDelegate in self.delegates) {
                     for (id<SNMLog> aLog in logArray) {
                       [aDelegate channel:self willSendLog:aLog];
                     }
                   }
                   
                   SNMLogContainer *container = [[SNMLogContainer alloc] initWithBatchId:batchId andLogs:logArray];
                   SNMLogVerbose(@"INFO:Sending log %@", [container serializeLogWithPrettyPrinting:YES]);

                   [self.sender sendAsync:container
                            callbackQueue:self.callbackQueue
                        completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {
                          SNMLogVerbose(@"INFO:HTTP response received with the "
                                        @"status code:%lu",
                                        (unsigned long)statusCode);

                          // Remove from pending log and storage.
                          [self.pendingLogsIds removeObject:batchId];
                          [self.storage deleteLogsForId:batchId withStorageKey:self.configuration.name];
                        }];
                 }
               }
             }];
}

#pragma mark - Timer

- (void)startTimer {
  [self resetTimer];

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, NSEC_PER_SEC * self.configuration.flushInterval),
                            1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.timerSource, ^{
    typeof(self) strongSelf = weakSelf;

    if (strongSelf->_itemsCount > 0) {
      [strongSelf flushQueue];
    }
    [strongSelf resetTimer];
  });
  dispatch_resume(self.timerSource);
}

- (void)resetTimer {
  if (self.timerSource) {
    dispatch_source_cancel(self.timerSource);
    self.timerSource = nil;
  }
}

#pragma mark - Storage

/**
 *  Delete all logs from the storage.
 */
- (void)deleteAllLogs {
  [self.storage deleteLogsForStorageKey:self.configuration.name];
}

@end
