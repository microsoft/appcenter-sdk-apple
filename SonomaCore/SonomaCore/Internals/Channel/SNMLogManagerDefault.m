/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMChannelDefault.h"
#import "SNMLogManagerDefault.h"
#import "SonomaCore+Internal.h"

static char *const SNMDataItemsOperationsQueue = "com.microsoft.sonoma.LogManagerQueue";

@implementation SNMLogManagerDefault

#pragma mark - Initialization

// TODO: Channels need to be passed in, otherwise e.g. old crashes will never been send out.

- (instancetype)init {
  if (self = [super init]) {
    dispatch_queue_t serialQueue = dispatch_queue_create(SNMDataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
    _channels = [NSMutableDictionary<NSNumber *, id<SNMChannel>> new];
    _listeners = [NSMutableArray<id<SNMLogManagerDelegate>> new];
    _deviceTracker = [[SNMDeviceTracker alloc] init];
  }
  return self;
}

- (instancetype)initWithSender:(id<SNMSender>)sender storage:(id<SNMStorage>)storage {
  if (self = [self init]) {
    _sender = sender;
    _storage = storage;
  }
  return self;
}

#pragma mark - Listener

- (void)addDelegate:(id<SNMLogManagerDelegate>)delegate {

  // Check if delegate is not already added.
  if (![self.listeners containsObject:delegate])
    [self.listeners addObject:delegate];
}

- (void)removeDelegate:(id<SNMLogManagerDelegate>)delegate {
  [self.listeners removeObject:delegate];
}

#pragma mark - Process items

- (void)processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {

  // Notify listeners.
  [self.listeners
      enumerateObjectsUsingBlock:^(id<SNMLogManagerDelegate> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [obj onProcessingLog:log withPriority:priority];
      }];

  // Get the channel.
  id<SNMChannel> channel = [self channelForPriority:priority];

  // Set common log info.
  log.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log.device = self.deviceTracker.device;

  dispatch_async(self.dataItemsOperations, ^{
    [channel enqueueItem:log];
  });
}

- (void) flushPendingLogsForPriority:(SNMPriority)priority {
  id<SNMChannel> channel = [self channelForPriority:@(priority)];

  [channel flushQueue];
}

#pragma mark - Helpers

- (id<SNMChannel>)createChannelForPriority:(SNMPriority)priority {
  SNMChannelDefault *channel;
  SNMChannelConfiguration *configuration = [SNMChannelConfiguration configurationForPriority:priority];
  if (configuration) {
    channel = [[SNMChannelDefault alloc] initWithSender:self.sender
                                                storage:self.storage
                                          configuration:configuration
                                          callbackQueue:self.dataItemsOperations];
    self.channels[@(priority)] = channel;
  }
  return channel;
}

- (id<SNMChannel>)channelForPriority:(SNMPriority)priority {

  // Return an existing channel or create it.
  id<SNMChannel> channel = [self.channels objectForKey:@(priority)];
  return (channel) ? channel : [self createChannelForPriority:priority];
}

#pragma mark - Storage

- (void)deleteLogsForPriority:(SNMPriority)priority {
  [[self channelForPriority:priority] deleteAllLogs];
}

@end
