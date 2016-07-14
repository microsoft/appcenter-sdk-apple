/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefault.h"
#import "AvalancheHub+Internal.h"

static char *const AVADataItemsOperationsQueue =
    "com.microsoft.avalanche.ChannelQueue";
static NSUInteger const AVADefaultBatchSize = 50;
static float const AVADefaultFlushInterval = 3.0;
static NSString* const kAVAStorageKey = @"storageKey";

@implementation AVAChannelDefault

@synthesize batchSize = _batchSize;
@synthesize flushInterval = _flushInterval;
@synthesize lastQueuedLogTime = _lastQueuedLogTime;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _itemsCount = 0;
    _batchSize = AVADefaultBatchSize;
    _flushInterval = AVADefaultFlushInterval;
    dispatch_queue_t serialQueue = dispatch_queue_create(
        AVADataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
  }
  return self;
}

- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
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

  // Update the queued time
  _lastQueuedLogTime = [NSDate date];
  
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.dataItemsOperations, ^{
    typeof(self) strongSelf = weakSelf;

    // TODO: Pass object to storage
    _itemsCount += 1;
    
    // save log
    [self.storage saveLog:item withStorageKey:kAVAStorageKey];
    
    if (completion)
      completion(YES);

    if (strongSelf->_itemsCount >= self.batchSize) {
      [strongSelf flushQueue];
    } else if (strongSelf->_itemsCount == 1) {
      [strongSelf startTimer];
    }
  });
}

- (void)flushQueue {
  // TODO: Get batch from storage and forward it to sender
  _itemsCount = 0;
  
  [self.storage loadLogsForStorageKey:kAVAStorageKey withCompletion:^(NSArray<AVALog> * _Nonnull logArray, NSString * _Nonnull batchId) {
    
    AVALogContainer* container = [[AVALogContainer alloc] initWithBatchId:batchId andLogs:logArray];
    
    AVALogVerbose(@"INFO:Sending log %@", [container serializeLog]);
    
    [self.sender sendAsync:container completionHandler:^(NSError *error, NSUInteger statusCode, NSString *batchId) {
      
      AVALogVerbose(@"INFO:HTTP response received with the status code:%ld", statusCode);
    }];
  }];
}

- (NSUInteger)batchSize {
  if (_batchSize <= 0) {
    return AVADefaultBatchSize;
  }
  return _batchSize;
}

#pragma mark - Timer

- (void)startTimer {
  if (self.flushInterval <= 0) {
    return;
  }
  [self resetTimer];

  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                            self.dataItemsOperations);
  dispatch_source_set_timer(
      self.timerSource,
      dispatch_walltime(NULL, NSEC_PER_SEC * self.flushInterval),
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
