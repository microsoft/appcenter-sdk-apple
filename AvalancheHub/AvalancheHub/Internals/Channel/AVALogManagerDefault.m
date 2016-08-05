/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefault.h"
#import "AVALogManagerDefault.h"
#import "AvalancheHub+Internal.h"

static char *const AVADataItemsOperationsQueue = "com.microsoft.avalanche.LogManagerQueue";

@implementation AVALogManagerDefault

#pragma mark - Initialisation

// TODO: Channels need to be passed in, otherwise e.g. old crashes will never been send out.

- (instancetype)init {
  if (self = [super init]) {
    dispatch_queue_t serialQueue = dispatch_queue_create(AVADataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
    _channels = [NSMutableDictionary<NSNumber *, id<AVAChannel>> new];
  }
  return self;
}

- (instancetype)initWithSender:(id<AVASender>)sender storage:(id<AVAStorage>)storage {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
  }
  return self;
}

#pragma mark - Process items

- (void)processLog:(id<AVALog>)log withPriority:(AVAPriority)priority {
  id<AVAChannel> channel = [self.channels objectForKey:@(priority)];
  if (!channel) {
    channel = [self createChannelForPriority:priority];
  }
  dispatch_async(self.dataItemsOperations, ^{
    [channel enqueueItem:log];
  });
}

#pragma mark - Helpers

- (id<AVAChannel>)createChannelForPriority:(AVAPriority)priority {
  AVAChannelDefault *channel;
  AVAChannelConfiguration *configuration = [AVAChannelConfiguration configurationForPriority:priority];
  if (configuration) {
    channel = [[AVAChannelDefault alloc] initWithSender:self.sender
                                                storage:self.storage
                                          configuration:configuration
                                          callbackQueue:self.dataItemsOperations];
    self.channels[@(priority)] = channel;
  }
  return channel;
}

@end
