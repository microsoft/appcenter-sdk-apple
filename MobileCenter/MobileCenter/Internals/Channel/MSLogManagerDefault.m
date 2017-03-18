#import "MSChannelDefault.h"
#import "MSFileStorage.h"
#import "MSHttpSender.h"
#import "MSIngestionSender.h"
#import "MSLogManagerDefault.h"
#import "MSLogManagerDefaultPrivate.h"
#import "MSMobileCenterErrors.h"
#import "MobileCenter+Internal.h"

static char *const MSlogsDispatchQueue = "com.microsoft.azure.mobile.mobilecenter.LogManagerQueue";

/**
 * Private declaration of the log manager.
 */
@interface MSLogManagerDefault ()

/**
 * A boolean value set to YES if this instance is enabled or NO otherwise.
 */
@property BOOL enabled;

@end

@implementation MSLogManagerDefault

#pragma mark - Initialization

- (instancetype)initWithAppSecret:(NSString *)appSecret installId:(NSUUID *)installId logUrl:(NSString *)logUrl {
  self = [self initWithSender:[[MSIngestionSender alloc] initWithBaseUrl:logUrl
                                  headers:@{
                                    kMSHeaderContentTypeKey : kMSContentType,
                                    kMSHeaderAppSecretKey : appSecret,
                                    kMSHeaderInstallIDKey : [installId UUIDString]
                                  }
                                  queryStrings:@{
                                    kMSAPIVersionKey : kMSAPIVersion
                                  }
                                  reachability:[MS_Reachability reachabilityForInternetConnection]
                                  retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]]
                      storage:[[MSFileStorage alloc] init]];
  return self;
}

- (instancetype)initWithSender:(MSHttpSender *)sender storage:(id<MSStorage>)storage {
  if ((self = [self init])) {
    dispatch_queue_t serialQueue = dispatch_queue_create(MSlogsDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _enabled = YES;
    _logsDispatchQueue = serialQueue;
    _channels = [NSMutableDictionary<NSString *, id<MSChannel>> new];
    _delegates = [NSHashTable weakObjectsHashTable];
    _sender = sender;
    _storage = storage;
  }
  return self;
}

#pragma mark - Delegate

- (void)addDelegate:(id<MSLogManagerDelegate>)delegate {
  [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<MSLogManagerDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - Channel Delegate

- (void)addChannelDelegate:(id<MSChannelDelegate>)channelDelegate
                forGroupID:(NSString *)groupID
              withPriority:(MSPriority)priority {
  if (channelDelegate) {
    id<MSChannel> channel = [self channelForGroupID:groupID withPriority:priority];
    [channel addDelegate:channelDelegate];
  }
}

- (void)removeChannelDelegate:(id<MSChannelDelegate>)channelDelegate
                   forGroupID:(NSString *)groupID
                 withPriority:(MSPriority)priority {
  if (channelDelegate) {
    id<MSChannel> channel = [self channelForGroupID:groupID withPriority:priority];
    [channel removeDelegate:channelDelegate];
  }
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<MSLogManagerDelegate> delegate))block {
  for (id<MSLogManagerDelegate> delegate in self.delegates) {
    if (delegate && [delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

#pragma mark - Process items

- (void)processLog:(id<MSLog>)log withPriority:(MSPriority)priority andGroupID:(NSString *)groupID {
  if (!log) {
    return;
  }

  // Internal ID to keep track of logs between modules.
  NSString *internalLogId = MS_UUID_STRING;

  // Notify delegates.
  [self enumerateDelegatesForSelector:@selector(onEnqueuingLog:withInternalId:andPriority:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {
                              [delegate onEnqueuingLog:log withInternalId:internalLogId andPriority:priority];
                            }];

  // Get the channel.
  id<MSChannel> channel = [self createChannelForGroupID:groupID withPriority:priority];

  // Set common log info.
  log.toffset = [NSNumber numberWithLongLong:[MSUtil nowInMilliseconds]];

  // Only add device info in case the log doesn't have one. In case the log is restored after a crash or for crashes,
  // We don't want the device information to be updated but want the old one preserved.
  if (!log.device) {
    log.device = [[MSDeviceTracker sharedInstance] device];
  }

  // Asynchronously forward to channel by using the data dispatch queue.
  [channel enqueueItem:log
        withCompletion:^(BOOL success) {
          if (success) {

            // Notify delegates.
            [self enumerateDelegatesForSelector:@selector(onFinishedPersistingLog:withInternalId:andPriority:)
                                      withBlock:^(id<MSLogManagerDelegate> delegate) {
                                        [delegate onFinishedPersistingLog:log
                                                           withInternalId:internalLogId
                                                              andPriority:priority];
                                      }];
          } else {

            // Notify delegates.
            [self enumerateDelegatesForSelector:@selector(onFailedPersistingLog:withInternalId:andPriority:)
                                      withBlock:^(id<MSLogManagerDelegate> delegate) {
                                        [delegate onFailedPersistingLog:log
                                                         withInternalId:internalLogId
                                                            andPriority:priority];
                                      }];
          }
        }];
}

#pragma mark - Helpers

- (id<MSChannel>)createChannelForGroupID:(NSString *)groupID withPriority:(MSPriority)priority {
  MSChannelDefault *channel;
  MSChannelConfiguration *configuration = [MSChannelConfiguration configurationForPriority:priority];
  if (configuration) {
    channel = [[MSChannelDefault alloc] initWithSender:self.sender
                                               storage:self.storage
                                         configuration:configuration
                                               groupID:groupID
                                     logsDispatchQueue:self.logsDispatchQueue];
    self.channels[groupID] = channel;
  }
  return channel;
}

- (id<MSChannel>)channelForGroupID:(NSString *)groupID withPriority:(MSPriority)priority {

  // Return an existing channel or create it.
  id<MSChannel> channel = [self.channels objectForKey:groupID];
  return (channel) ? channel : [self createChannelForGroupID:groupID withPriority:priority];
}

#pragma mark - Enable / Disable

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  if (isEnabled != self.enabled) {
    self.enabled = isEnabled;

    // Propagate to sender.
    // Sender will in turn propagates to its channel delegates.
    [self.sender setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];

    // If requested, also delete logs from not started services.
    if (!isEnabled && deleteData) {
      NSArray<NSString *> *runningChannels = self.channels.allKeys;
      for (NSString *groupID in runningChannels) {
        if (![runningChannels containsObject:groupID]) {
          NSError *error = [NSError errorWithDomain:kMSMCErrorDomain
                                               code:kMSMCConnectionSuspendedErrorCode
                                           userInfo:@{NSLocalizedDescriptionKey : kMSMCConnectionSuspendedErrorDesc}];
          [[self.channels objectForKey:groupID] deleteAllLogsWithError:error];
        }
      }
    }
  }
}

- (void)setEnabled:(BOOL)isEnabled
    andDeleteDataOnDisabled:(BOOL)deleteData
                 forGroupID:(NSString *)groupID
               withPriority:(MSPriority)priority {
  [[self channelForGroupID:groupID withPriority:priority] setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
}

#pragma mark - Other public methods

- (void)setLogUrl:(NSString *)logUrl {
  self.sender.baseURL = logUrl;
}

@end
