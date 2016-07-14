/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogManagerDefault.h"
#import "AvalancheHub+Internal.h"

static char *const AVADataItemsOperationsQueue =
    "com.microsoft.avalanche.LogManagerQueue";

@implementation AVALogManagerDefault

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    dispatch_queue_t serialQueue = dispatch_queue_create(
        AVADataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
  }
  return self;
}

- (instancetype)initWithChannels:(NSArray<AVAChannel> *)channels {
  if (self = [self init]) {
    _channels = [self channelDictWithChannels:channels];
  }
  return self;
}

#pragma mark - Process items

- (void)processLog:(id<AVALog>)log withPriority:(AVASendPriority)priority {
  id<AVAChannel> channel = self.channels[@(priority)];
  dispatch_async(self.dataItemsOperations, ^{
    [channel enqueueItem:log];
  });
}

#pragma mark - Helpers

- (NSDictionary *)channelDictWithChannels:(NSArray<AVAChannel> *)channels {
  NSMutableDictionary<NSString *, id<AVAChannel>> *channelsDict =
      [NSMutableDictionary<NSString *, id<AVAChannel>> new];
  for (id<AVAChannel> channel in channels) {
    channelsDict[@(channel.priority)] = channel;
  }
  return [channelsDict copy];
}

@end
