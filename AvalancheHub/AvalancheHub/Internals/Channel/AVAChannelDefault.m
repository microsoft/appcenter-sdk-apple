/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefault.h"
#import "AvalancheHub+Internal.h"

@implementation AVAChannelDefault

@synthesize configuration = _configuration;
@synthesize priority = _priority;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _itemsCount = 0;
    _pendingLogsIds = [NSMutableArray new];
  }
  return self;
}

- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage
                      priority:(AVASendPriority)priority {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
    _priority = priority;
    _configuration = [AVAChannelConfiguration configurationForPriority:priority];
  }
  return self;
}

#pragma mark - Managing queue

- (void)enqueueItem:(id<AVALog>)item {
  [self enqueueItem:item withCompletion:nil];
}

- (void)enqueueItem:(id<AVALog>)item
     withCompletion:(enqueueCompletionBlock)completion {
  if (!item) {
    AVALogWarning(@"WARNING: TelemetryItem was nil.");
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
             withCompletion:^(NSArray<AVALog> *_Nonnull logArray,
                              NSString *_Nonnull batchId) {

               if (self.pendingLogsIds.count < self.configuration.pendingBatchesLimit) {
                 [self.pendingLogsIds addObject:batchId];
                 AVALogContainer *container =
                     [[AVALogContainer alloc] initWithBatchId:batchId
                                                      andLogs:logArray];

                 AVALogVerbose(@"INFO:Sending log %@",
                               [container serializeLog]);

                 [self.sender sendAsync:container
                      completionHandler:^(NSError *error, NSUInteger statusCode,
                                          NSString *batchId) {
                        AVALogVerbose(@"INFO:HTTP response received with the "
                                      @"status code:%ld",
                                      statusCode);
                        [self.pendingLogsIds removeObject:batchId];
                        // TODO: Check if status code is recoverable. if so
                        // block channel for now
                        BOOL isRecoverable = YES;
                        if (isRecoverable) {

                        } else {
                          [self.storage deleteLogsForId:batchId
                                         withStorageKey:self.configuration.name];
                        }
                        // TODO: Delete item if neccessary
                        // TODO: Remove item from pending

                      }];
               }

             }];
}

#pragma mark - Timer

- (void)startTimer {
  [self resetTimer];

  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  self.timerSource =
      dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  dispatch_source_set_timer(
      self.timerSource,
      dispatch_walltime(NULL, NSEC_PER_SEC * self.configuration.flushInterval),
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

@end
