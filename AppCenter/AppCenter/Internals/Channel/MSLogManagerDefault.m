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
@interface MSLogManagerDefault () <MSChannelDelegate, MSSenderDelegate>

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
    [sender addDelegate:self];
    _storage = storage;
    _flushedChannelsCount = 0;
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    _backgroundTaskLockToken = [NSObject new];
    _appDidEnterBackgroundObserver = nil;
    _appWillEnterForegroundObserver = nil;
    [self addObservers];
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
    [channel addDelegate:self];
    self.channels[configuration.groupId] = channel;
  }
}

#pragma mark - Object life cycle

- (void)dealloc {
  [self removeObservers];
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
                               * If the delegate doesn't have a groupId implementation, it assumes that the delegate is
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
                               * If the delegate doesn't have a groupId implementation, it assumes that the delegate is
                               * interested in all kinds of logs. Otherwise, compare groupId.
                               */
                              if (![delegate respondsToSelector:@selector(groupId)] ||
                                  [[delegate groupId] isEqualToString:[channel.configuration groupId]]) {
                                [delegate didFailSendingLog:log withError:error];
                              }
                            }];
}

#pragma mark - Sender Delegate

- (void)senderDidSuspend:(id<MSSender>)sender {
  (void)sender;
  
  // Cancel the background task if the connection was lost.
#if !TARGET_OS_OSX
  @synchronized(self.backgroundTaskLockToken) {
    [self endBackgroundActivity];
  }
#endif
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

    // Own enable logic.
    if (isEnabled) {
      [self addObservers];
    } else {
#if !TARGET_OS_OSX
      [self endBackgroundActivity];
#endif
      [self removeObservers];
    }

    // If requested, also delete logs from not started services.
    if (!isEnabled && deleteData) {
      NSArray<NSString *> *runningChannels = self.channels.allKeys;
      for (NSString *groupId in runningChannels) {
        if (![runningChannels containsObject:groupId]) {
          NSError *error = [NSError errorWithDomain:kMSACErrorDomain
                                               code:kMSACConnectionSuspendedErrorCode
                                           userInfo:@{NSLocalizedDescriptionKey : kMSACConnectionSuspendedErrorDesc}];
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

#pragma mark – Observers

- (void)addObservers {

// There is no need to do trigger sending on macOS because we can just continue to execute tasks there.
#if !TARGET_OS_OSX
  if (!MS_IS_APP_EXTENSION) {
    @synchronized(self.backgroundTaskLockToken) {
      self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
      __weak typeof(self) weakSelf = self;
      if (self.appDidEnterBackgroundObserver == nil) {
        self.appDidEnterBackgroundObserver =
            [MS_NOTIFICATION_CENTER addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                object:nil
                                                 queue:NSOperationQueue.mainQueue
                                            usingBlock:^(NSNotification __unused *note) {
                                              typeof(self) strongSelf = weakSelf;
                                              if (strongSelf) {
                                                [strongSelf applicationDidEnterBackground];
                                              }
                                            }];
      }
      if (self.appWillEnterForegroundObserver == nil) {
        self.appWillEnterForegroundObserver =
            [MS_NOTIFICATION_CENTER addObserverForName:UIApplicationWillEnterForegroundNotification
                                                object:nil
                                                 queue:NSOperationQueue.mainQueue
                                            usingBlock:^(NSNotification __unused *note) {
                                              dispatch_async(self.logsDispatchQueue, ^{
                                                typeof(self) strongSelf = weakSelf;
                                                if (strongSelf) {
                                                  [strongSelf applicationWillEnterForeground];
                                                }
                                              });
                                            }];
      }
    }
  }
#endif
}

- (void)removeObservers {
#if !TARGET_OS_OSX
  if (!MS_IS_APP_EXTENSION) {
    id strongBackgroundObserver = self.appDidEnterBackgroundObserver;
    if (strongBackgroundObserver) {
      [MS_NOTIFICATION_CENTER removeObserver:strongBackgroundObserver];
      self.appDidEnterBackgroundObserver = nil;
    }
    id strongForegroundObserver = self.appWillEnterForegroundObserver;
    if (strongForegroundObserver) {
      [MS_NOTIFICATION_CENTER removeObserver:strongForegroundObserver];
      self.appWillEnterForegroundObserver = nil;
    }
  }
#endif
}

#pragma mark - Application life cycle

#if !TARGET_OS_OSX
/**
 *  The application will go to the background.
 */
- (void)applicationDidEnterBackground {
  
  /*
   * From the documentation for applicationDidEnterBackground:
   * "It's likely any background tasks you start in applicationDidEnterBackground: will not run until after
   * that method exits, you should request additional background execution time before starting those tasks.
   * In other words, first call beginBackgroundTaskWithExpirationHandler: and then run the task on a
   * dispatch queue or secondary thread.
   */
  UIApplication *sharedApplication = [MSUtility sharedApplication];
  
  // Checking if sharedApplication is != nil as it can be nil for extensions.
  if (sharedApplication && self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
    self.backgroundTaskIdentifier = [sharedApplication beginBackgroundTaskWithExpirationHandler:^{
      
      // Suspend the sender, it will also suspend all channels.
      @synchronized(self.backgroundTaskLockToken) {
        MSLogDebug([MSAppCenter logTag], @"Background task has expired.");
        
        // Disable sender so that network changes in background won't affect his state.
        [self.sender setEnabled:NO andDeleteDataOnDisabled:NO];
      }
    }];
  }
  
  // Init block to handle all the channels flushing notifications.
  __weak typeof(self) weakSelf = self;
  MSForceFlushCompletionBlock completion = ^() {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf channelForceFlushingCompleted];
    }
  };
  
  // There is now extended time to flush the last few logs from the channels.
  for (NSString *groupId in self.channels) {
    [self.channels[groupId] forceFlushWithCompletion:completion];
  }
}

/**
 *  The application will go to the foreground.
 */
- (void)applicationWillEnterForeground {
  @synchronized(self.backgroundTaskLockToken) {
    
    // In foreground now, cancel any pending background task.
    [self endBackgroundActivity];
    
    // Re-enable sender.
    [self.sender setEnabled:YES andDeleteDataOnDisabled:NO];
    
    /**
     * TODO: Needs some refactoring, sender is coupled to too many objects.
     * It's hard to follow what's enabled or not.
     * I think it should only be coupled to chanels, and perhaps having a
     * sender per channel would simplify things.
     *
     * The sender may not be disabled because the app as been forgrounded
     * before all the channels finished flushing,
     * so we still have to resume the suspended channels and cancel the ones
     * not suspended yet.
     */
    for (NSString *groupId in self.channels) {
      [self.channels[groupId] cancelForceFlushing];
    }
  }
}
#endif


#pragma mark - Other public methods

- (void)setLogUrl:(NSString *)logUrl {
  self.sender.baseURL = logUrl;
}

#pragma mark - Other private methods

#if !TARGET_OS_OSX
- (void)channelForceFlushingCompleted {
  @synchronized(self.backgroundTaskLockToken) {
    
    // Background task is still going on.
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
      self.flushedChannelsCount++;
      
      // All channels have finished flushing.
      if (self.channels.count == self.flushedChannelsCount) {
        
        // Disable sender so that network changes in background won't affect his state.
        [self.sender setEnabled:NO andDeleteDataOnDisabled:NO];
        [self endBackgroundActivity];
      }
    }
  }
}

- (void)endBackgroundActivity {
  if (!MS_IS_APP_EXTENSION) {

    // Reset flushed channels count.
    self.flushedChannelsCount = 0;

    // Invalidate background task.
    UIApplication *sharedApplication = [MSUtility sharedApplication];
    if (sharedApplication && self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
      [sharedApplication endBackgroundTask:self.backgroundTaskIdentifier];
      self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
      MSLogDebug([MSAppCenter logTag], @"Background task invalidated.");
    }
  }
}
#endif

@end
