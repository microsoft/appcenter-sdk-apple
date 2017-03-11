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
                                                               appSecret:appSecret
                                                               installId:[installId UUIDString]]
                      storage:[[MSFileStorage alloc] init]];
  return self;
}

- (instancetype)initWithSender:(MSHttpSender *)sender storage:(id<MSStorage>)storage {
  if ((self = [self init])) {
    dispatch_queue_t serialQueue = dispatch_queue_create(MSlogsDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _enabled = YES;
    _logsDispatchQueue = serialQueue;
    _channels = [NSMutableDictionary<NSNumber *, id<MSChannel>> new];
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

- (void)addChannelDelegate:(id<MSChannelDelegate>)channelDelegate forPriority:(MSPriority)priority {
  if (channelDelegate) {
    id<MSChannel> channel = [self channelForPriority:priority];
    [channel addDelegate:channelDelegate];
  }
}

- (void)removeChannelDelegate:(id<MSChannelDelegate>)channelDelegate forPriority:(MSPriority)priority {
  if (channelDelegate) {
    id<MSChannel> channel = [self channelForPriority:priority];
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

- (void)processLog:(id<MSLog>)log withPriority:(MSPriority)priority {

  if (!log) {
    return;
  }

  // Notify delegates.
  [self enumerateDelegatesForSelector:@selector(onProcessingLog:withPriority:)
                            withBlock:^(id<MSLogManagerDelegate> delegate) {
                              [delegate onProcessingLog:log withPriority:priority];
                            }];

  // Get the channel.
  id<MSChannel> channel = [self channelForPriority:priority];

  // Set common log info.
  log.toffset = [NSNumber numberWithLongLong:[MSUtil nowInMilliseconds]];

  // Only add device info in case the log doesn't have one. In case the log is restored after a crash or for crashes,
  // We don't want the device information to be updated but want the old one preserved.
  if (!log.device) {
    log.device = [[MSDeviceTracker sharedInstance] device];
  }

  // Asynchronously forward to channel by using the data dispatch queue.
  [channel enqueueItem:log];
}

#pragma mark - Helpers

- (id<MSChannel>)createChannelForPriority:(MSPriority)priority {
  MSChannelDefault *channel;
  MSChannelConfiguration *configuration = [MSChannelConfiguration configurationForPriority:priority];
  if (configuration) {
    channel = [[MSChannelDefault alloc] initWithSender:self.sender
                                               storage:self.storage
                                         configuration:configuration
                                     logsDispatchQueue:self.logsDispatchQueue];
    self.channels[@(priority)] = channel;
  }
  return channel;
}

- (id<MSChannel>)channelForPriority:(MSPriority)priority {

  // Return an existing channel or create it.
  id<MSChannel> channel = [self.channels objectForKey:@(priority)];
  return (channel) ? channel : [self createChannelForPriority:priority];
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
      NSArray<NSNumber *> *runningPriorities = self.channels.allKeys;
      for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
        if (![runningPriorities containsObject:@(priority)]) {
          NSError *error = [NSError errorWithDomain:kMSMCErrorDomain
                                               code:kMSMCConnectionSuspendedErrorCode
                                           userInfo:@{NSLocalizedDescriptionKey : kMSMCConnectionSuspendedErrorDesc}];
          [[self channelForPriority:priority] deleteAllLogsWithError:error];
        }
      }
    }
  }
}

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forPriority:(MSPriority)priority {
  [[self channelForPriority:priority] setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
}

#pragma mark - Other public methods

- (void)setLogUrl:(NSString*)logUrl{
  self.sender.baseURL = logUrl;
}

@end
