/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDefault.h"
#import "AVALogManagerDefault.h"
#import "SonomaCore+Internal.h"

static char *const AVADataItemsOperationsQueue = "com.microsoft.avalanche.LogManagerQueue";

@implementation AVALogManagerDefault

#pragma mark - Initialization

// TODO: Channels need to be passed in, otherwise e.g. old crashes will never been send out.

- (instancetype)init {
  if (self = [super init]) {
    dispatch_queue_t serialQueue = dispatch_queue_create(AVADataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
    _channels = [NSMutableDictionary<NSNumber *, id<AVAChannel>> new];
    _listeners = [NSMutableArray<id<AVALogManagerListener>> new];
    _deviceTracker = [[AVADeviceTracker alloc] init];
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

#pragma mark - Listener

- (void)addListener:(id <AVALogManagerListener>)listener {
  
  // Check if listener is not already added.
  if (![self.listeners containsObject:listener])
    [self.listeners addObject:listener];
}

- (void)removeListener:(id <AVALogManagerListener>)listener {
  [self.listeners removeObject:listener];
}

#pragma mark - Process items

- (void)processLog:(id<AVALog>)log withPriority:(AVAPriority)priority {
  
  // Notify listeners.
  [self.listeners enumerateObjectsUsingBlock:^(id<AVALogManagerListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [obj onProcessingLog:log withPriority:priority];
  }];
  
  id<AVAChannel> channel = [self.channels objectForKey:@(priority)];
  if (!channel) {
    channel = [self createChannelForPriority:priority];
  }
  
  // Set common log info.
  log.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log.device = self.deviceTracker.device;
  
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
