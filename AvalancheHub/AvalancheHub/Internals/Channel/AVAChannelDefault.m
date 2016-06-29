/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefaultPrivate.h"
#import "AvalancheHub+Internal.h"

static char *const AVADataItemsOperationsQueue = "com.microsoft.avalanche.ChannelQueue";
static NSInteger const AVADefaultBatchSize  = 50;
static NSInteger const AVADefaultFlushInterval = 15;

@implementation AVAChannelDefault 

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
  
}

@end
