/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefaultPrivate.h"
#import "AvalancheHub+Internal.h"

static char *const AVADataItemsOperationsQueue = "com.microsoft.avalanche.ChannelQueue";
static NSInteger const AVADefaultBatchSize  = 50;
static NSInteger const AVADefaultFlushInterval = 15;

@implementation AVAChannelDefault 

@synthesize batchSize = _batchSize;
@synthesize flushInterval = _flushInterval;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    _itemsCount = 0;
    _batchSize = AVADefaultBatchSize;
    _flushInterval = AVADefaultFlushInterval;
    dispatch_queue_t serialQueue = dispatch_queue_create(AVADataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
  }
  return self;
}

- (instancetype)initWithSender:(id<AVASender>)sender storage:(id<AVAStorage>) storage {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
  }
  return self;
}

#pragma mark - Managing queue

- (void)enqueueItem:(id<AVALog>) item {
  
  if (!item) {
    AVALogWarning(@"WARNING: TelemetryItem was nil.");
    return;
  }
  
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.dataItemsOperations, ^{
    typeof(self) strongSelf = weakSelf;
    
    // TODO: Pass object to storage
    
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
}


- (void)startTimer {
  [self resetTimer];
  
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.dataItemsOperations);
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, NSEC_PER_SEC * self.flushInterval), 1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
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
