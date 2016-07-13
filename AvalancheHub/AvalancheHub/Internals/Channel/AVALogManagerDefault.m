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

- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage
                      channels:(NSArray<AVAChannel> *)channels {
  if (self = [self init]) {
    _channels = [self channelDictWithChannels:channels];
  }

  return self;
}

#pragma mark - Process items

- (void)processLog:(id<AVALog>)log withPriority:(AVASendPriority)priority {
  NSString *key = kAVASendPriorityNames[priority];
  id<AVAChannel> channel = self.channels[key];
  dispatch_async(self.dataItemsOperations, ^{
    [channel enqueueItem:log];
  });
}

#pragma mark - Helpers

- (NSDictionary *)channelDictWithChannels:(NSArray<AVAChannel> *)channels {
  NSMutableDictionary<NSString *, id<AVAChannel>> *channelsDict =
      [NSMutableDictionary<NSString *, id<AVAChannel>> new];
  for (id<AVAChannel> channel in channels) {
    NSString *key = kAVASendPriorityNames[channel.priority];
    channelsDict[key] = channel;
  }
  return [channelsDict copy];
}

- (id<AVAChannel>)channelForPriotity:(AVASendPriority)priority {
  NSString *key = kAVASendPriorityNames[priority];
  id<AVAChannel> channel = self.channels[key];
  return channel;
}

@end
