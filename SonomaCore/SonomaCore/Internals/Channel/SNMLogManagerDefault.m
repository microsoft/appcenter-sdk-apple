/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMChannelDefault.h"
#import "SNMLogManagerDefault.h"
#import "SonomaCore+Internal.h"

static char *const SNMDataItemsOperationsQueue = "com.microsoft.sonoma.LogManagerQueue";

/**
 * Private declaration of the log manager.
 */
@interface SNMLogManagerDefault ()

/**
 *  A boolean value set to YES if this instance is enabled or NO otherwise.
 */
@property(atomic) BOOL enabled;

@end

@implementation SNMLogManagerDefault

#pragma mark - Initialization

- (instancetype)init {
  if (self = [super init]) {
    dispatch_queue_t serialQueue = dispatch_queue_create(SNMDataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _enabled = YES;
    _dataItemsOperations = serialQueue;
    _channels = [NSMutableDictionary<NSNumber *, id<SNMChannel>> new];
    _delegates = [NSHashTable weakObjectsHashTable];
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

#pragma mark - Delegate

- (void)addDelegate:(id<SNMLogManagerDelegate>)delegate {
  [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SNMLogManagerDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - Channel Delegate
- (void)addChannelDelegate:(id<SNMChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority {
  if (channelDelegate) {
    id<SNMChannel> channel = [self channelForPriority:priority];
    [channel addDelegate:channelDelegate];
  }
}

- (void)removeChannelDelegate:(id<SNMChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority {
  if (channelDelegate) {
    id<SNMChannel> channel = [self channelForPriority:priority];
    [channel removeDelegate:channelDelegate];
  }
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<SNMLogManagerDelegate> delegate))block {
  for (id<SNMLogManagerDelegate> delegate in self.delegates) {
    if (delegate && [delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

#pragma mark - Process items

- (void)processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {

  // Notify delegates.
  [self enumerateDelegatesForSelector:@selector(onProcessingLog:withPriority:)
                            withBlock:^(id<SNMLogManagerDelegate> delegate) {
                              [delegate onProcessingLog:log withPriority:priority];
                            }];

  // Get the channel.
  id<SNMChannel> channel = [self channelForPriority:priority];

  // Set common log info.
  log.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log.device = self.deviceTracker.device;

  // Asynchroneously forward to channel by using the data dispatch queue.
  [channel enqueueItem:log];
}

#pragma mark - Helpers

- (id<SNMChannel>)createChannelForPriority:(SNMPriority)priority {
  SNMChannelDefault *channel;
  SNMChannelConfiguration *configuration = [SNMChannelConfiguration configurationForPriority:priority];
  if (configuration) {
    channel = [[SNMChannelDefault alloc] initWithSender:self.sender
                                                storage:self.storage
                                          configuration:configuration
                                          logsDispatchQueue:self.dataItemsOperations];
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

#pragma mark - Enable / Disable

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  if (isEnabled != self.enabled) {
    self.enabled = isEnabled;

    // Propagate to sender.
    [self.sender setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];

    // Propagate to channels.
    for (NSNumber *priority in self.channels) {
      [self.channels[priority] setEnabled:isEnabled andDeleteDataOnDisabled:NO];
    }

    // If requested, delete any remaining logs (e.g., even logs from not started features).
    if (!isEnabled && deleteData) {
      for (int priority = 0; priority < kSNMPriorityCount; priority++) {
        [self deleteLogsForPriority:priority];
      }
    }
  }
}

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forPriority:(SNMPriority)priority {
  [[self channelForPriority:priority] setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
}

@end
