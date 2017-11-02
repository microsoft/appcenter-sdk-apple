#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSChannelDefault.h"
#import "MSChannelDelegate.h"
#import "MSHttpSender.h"
#import "MSIngestionSender.h"
#import "MSLogDBStorage.h"
#import "MSLogManagerDefault.h"
#import "MSLogManagerDefaultPrivate.h"

static char *const kMSlogsDispatchQueue = "com.microsoft.appcenter.LogManagerQueue";

/**
 * Private declaration of the log manager.
 */
@interface MSLogManagerDefault (MSChannelDelegate)

@end

@implementation MSLogManagerDefault

#pragma mark - Initialization

- (instancetype)initWithAppSecret:(NSString *)appSecret installId:(NSUUID *)installId logUrl:(NSString *)logUrl {
  self = [self initWithSender:[[MSIngestionSender alloc] initWithBaseUrl:logUrl
                                                               appSecret:appSecret
                                                               installId:[installId UUIDString]]
                      storage:[[MSLogDBStorage alloc] initWithCapacity:kMSStorageMaxCapacity]];
  return self;
}

- (instancetype)initWithSender:(MSHttpSender *)sender storage:(id<MSStorage>)storage {
  if ((self = [self init])) {
    dispatch_queue_t serialQueue = dispatch_queue_create(kMSlogsDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _enabled = YES;
    _logsDispatchQueue = serialQueue;
    _channels = [NSMutableDictionary<NSString *, id<MSChannel>> new];
    _delegates = [NSHashTable weakObjectsHashTable];
    _sender = sender;
    _storage = storage;
  }
  return self;
}

- (void)initChannelWithConfiguration:(MSChannelConfiguration *)configuration {
  MSChannelDefault *channel;
  if (configuration) {
    channel = [[MSChannelDefault alloc] initWithSender:self.sender
                                               storage:self.storage
                                         configuration:configuration
                                     logsDispatchQueue:self.logsDispatchQueue];
    [channel addDelegate:(id<MSChannelDelegate>)self];
    self.channels[configuration.groupId] = channel;
  }
}

#pragma mark - Delegate

- (void)addDelegate:(id<MSLogManagerDelegate>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSLogManagerDelegate>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<MSLogManagerDelegate> delegate))block {
  @synchronized(self) {
    for (id<MSLogManagerDelegate> delegate in self.delegates) {
      if (delegate && [delegate respondsToSelector:selector]) {
        block(delegate);
      }
    }
  }
}

#pragma mark - Channel Delegate

- (void)channel:(id<MSChannel>)channel willSendLog:(id<MSLog>)log {
  [self enumerateDelegatesForSelector:@selector(willSendLog:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {

                              /*
                               * If the delegate doesn't have groupId implementation, it assumes that the delegate is
                               * interested in all kinds of logs. Otherwise, compare groupId.
                               */
                              if (![delegate respondsToSelector:@selector(groupId)] ||
                                  [[delegate groupId] isEqualToString:[channel.configuration groupId]]) {
                                [delegate willSendLog:log];
                              }
                            }];
}

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  [self enumerateDelegatesForSelector:@selector(didSucceedSendingLog:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {

                              /*
                               * If the delegate doesn't have groupId implementation, it assumes that the delegate is
                               * interested in all kinds of logs. Otherwise, compare groupId.
                               */
                              if (![delegate respondsToSelector:@selector(groupId)] ||
                                  [[delegate groupId] isEqualToString:[channel.configuration groupId]]) {
                                [delegate didSucceedSendingLog:log];
                              }
                            }];
}

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  [self enumerateDelegatesForSelector:@selector(didFailSendingLog:withError:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {

                              /*
                               * If the delegate doesn't have groupId implementation, it assumes that the delegate is
                               * interested in all kinds of logs. Otherwise, compare groupId.
                               */
                              if (![delegate respondsToSelector:@selector(groupId)] ||
                                  [[delegate groupId] isEqualToString:[channel.configuration groupId]]) {
                                [delegate didFailSendingLog:log withError:error];
                              }
                            }];
}

#pragma mark - Process items

- (void)processLog:(id<MSLog>)log forGroupId:(NSString *)groupId {
  if (!log) {
    return;
  }

  // Get the channel.
  id<MSChannel> channel = self.channels[groupId];
  if (!channel) {
    MSLogWarning([MSAppCenter logTag], @"Channel has not been initialized for the group Id: %@", groupId);
    return;
  }

  // Internal ID to keep track of logs between modules.
  NSString *internalLogId = MS_UUID_STRING;

  /*
   * Set common log info.
   * Only add timestamp and device info in case the log doesn't have one. In case the log is restored after a crash or
   * for crashes, we don't want the timestamp and the device information to be updated but want the old one preserved.
   */
  if (!log.timestamp) {
    log.timestamp = [NSDate date];
  }
  if (!log.device) {
    log.device = [[MSDeviceTracker sharedInstance] device];
  }

  // Notify delegates.
  [self enumerateDelegatesForSelector:@selector(onPreparedLog:withInternalId:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {
                              [delegate onPreparedLog:log withInternalId:internalLogId];
                            }];
  [self enumerateDelegatesForSelector:@selector(onEnqueuingLog:withInternalId:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {
                              [delegate onEnqueuingLog:log withInternalId:internalLogId];
                            }];

  // Asynchronously forward to channel by using the data dispatch queue.
  [channel enqueueItem:log
        withCompletion:^(BOOL success) {
          if (success) {

            // Notify delegates.
            [self enumerateDelegatesForSelector:@selector(onFinishedPersistingLog:withInternalId:)
                                      withBlock:^(id<MSLogManagerDelegate> delegate) {
                                        [delegate onFinishedPersistingLog:log withInternalId:internalLogId];
                                      }];
          } else {

            // Notify delegates.
            [self enumerateDelegatesForSelector:@selector(onFailedPersistingLog:withInternalId:)
                                      withBlock:^(id<MSLogManagerDelegate> delegate) {
                                        [delegate onFailedPersistingLog:log withInternalId:internalLogId];
                                      }];
          }
        }];
}

#pragma mark - Enable / Disable

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  if (isEnabled != self.enabled) {
    self.enabled = isEnabled;

    // Propagate to sender.
    [self.sender setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];

    // Propagate to initialized channels.
    for (NSString *groupId in self.channels) {
      [self.channels[groupId] setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
    }

    // If requested, also delete logs from not started services.
    if (!isEnabled && deleteData) {
      NSArray<NSString *> *runningChannels = self.channels.allKeys;
      for (NSString *groupId in runningChannels) {
        if (![runningChannels containsObject:groupId]) {
          NSError *error = [NSError errorWithDomain:kMSMCErrorDomain
                                               code:kMSMCConnectionSuspendedErrorCode
                                           userInfo:@{NSLocalizedDescriptionKey : kMSMCConnectionSuspendedErrorDesc}];
          [self.channels[groupId] deleteAllLogsWithError:error];
        }
      }
    }
  }
}

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forGroupId:(NSString *)groupId {
  if (self.channels[groupId]) {
    [self.channels[groupId] setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
  } else {
    MSLogWarning([MSAppCenter logTag], @"Channel has not been initialized for the group Id: %@", groupId);
  }
}

#pragma mark - Suspend / Resume

- (void)suspend {

  // Disable sender, sending log will not be possible but they'll still be stored.
  [self.sender setEnabled:NO andDeleteDataOnDisabled:NO];
}

- (void)resume {

  // Resume sender, logs can be sent again. Pending logs are sent.
  [self.sender setEnabled:YES andDeleteDataOnDisabled:NO];
}

#pragma mark - Other public methods

- (void)setLogUrl:(NSString *)logUrl {
  self.sender.baseURL = logUrl;
}

@end
