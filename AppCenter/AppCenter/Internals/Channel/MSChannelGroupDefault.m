#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSChannelDelegate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitDefault.h"
#import "MSHttpSender.h"
#import "MSIngestionSender.h"
#import "MSLogDBStorage.h"
#import "MSStorage.h"

static char *const kMSlogsDispatchQueue = "com.microsoft.appcenter.ChannelGroupQueue";

@implementation MSChannelGroupDefault

#pragma mark - Initialization

- (instancetype)initWithAppSecret:(NSString *)appSecret installId:(NSUUID *)installId logUrl:(NSString *)logUrl {
  self = [self initWithSender:[[MSIngestionSender alloc] initWithBaseUrl:logUrl
                                                               appSecret:appSecret
                                                               installId:[installId UUIDString]]
                      storage:[[MSLogDBStorage alloc] initWithCapacity:kMSStorageMaxCapacity]];
  return self;
}

- (instancetype)initWithSender:(nullable MSHttpSender *)sender storage:(nullable id<MSStorage>)storage {
  if ((self = [self init])) {
    dispatch_queue_t serialQueue = dispatch_queue_create(kMSlogsDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _logsDispatchQueue = serialQueue;
    _channels = [NSMutableArray<id<MSChannelUnitProtocol>> new];
    _delegates = [NSHashTable weakObjectsHashTable];
    _sender = sender;
    _storage = storage;
  }
  return self;
}

- (id<MSChannelUnitProtocol>)addChannelUnitWithConfiguration:(MSChannelUnitConfiguration *)configuration {
  MSChannelUnitDefault *channel;
  if (configuration) {
    channel = [[MSChannelUnitDefault alloc] initWithSender:self.sender
                                                   storage:self.storage
                                             configuration:configuration
                                         logsDispatchQueue:self.logsDispatchQueue];
    [channel addDelegate:(id<MSChannelDelegate>)self];
    [self.channels addObject:channel];
  }
  return channel;
}

#pragma mark - Delegate

- (void)addDelegate:(id<MSChannelDelegate>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSChannelDelegate>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<MSChannelDelegate> delegate))block {
  @synchronized(self) {
    for (id<MSChannelDelegate> delegate in self.delegates) {
      if (delegate && [delegate respondsToSelector:selector]) {
        block(delegate);
      }
    }
  }
}

#pragma mark - Channel Delegate

- (void)channel:(id<MSChannelProtocol>)channel willSendLog:(id<MSLog>)log {
  [self enumerateDelegatesForSelector:@selector(channel:willSendLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel willSendLog:log];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didSucceedSendingLog:(id<MSLog>)log {
  [self enumerateDelegatesForSelector:@selector(channel:didSucceedSendingLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didSucceedSendingLog:log];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  [self enumerateDelegatesForSelector:@selector(channel:didFailSendingLog:withError:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didFailSendingLog:log withError:error];
                            }];
}

-(BOOL)shouldFilterLog:(id<MSLog>)log {
  __block BOOL shouldFilter = NO;
  [self enumerateDelegatesForSelector:@selector(shouldFilterLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              shouldFilter = shouldFilter || [delegate shouldFilterLog:log];
                            }];
  return shouldFilter;
}

- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  [self enumerateDelegatesForSelector:@selector(onEnqueuingLog:withInternalId:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate onEnqueuingLog:log withInternalId:internalId];
                            }];
}

- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  [self enumerateDelegatesForSelector:@selector(onFinishedPersistingLog:withInternalId:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate onFinishedPersistingLog:log withInternalId:internalId];
                            }];
}

- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  [self enumerateDelegatesForSelector:@selector(onFailedPersistingLog:withInternalId:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate onFailedPersistingLog:log withInternalId:internalId];
                            }];
}

#pragma mark - Enable / Disable

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {

  // Propagate to sender.
  [self.sender setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];

  // Propagate to initialized channels.
  for (id<MSChannelProtocol> channel in self.channels) {
    [channel setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
  }

  /**
   * TODO: There should be some concept of logs on disk expiring to avoid leaks
   * when a channel is disabled with lingering logs but never enabled again.
   *
   * Note that this is an unlikely scenario. Solving this issue is more of a
   * proactive measure.
   */
}

#pragma mark - Suspend / Resume

- (void)suspend {

  // Disable sender, sending log will not be possible but they'll still be stored.
  [self.sender setEnabled:NO andDeleteDataOnDisabled:NO];

  // Suspend each channel asynchronously.
  for (id<MSChannelProtocol> channel in self.channels) {
    dispatch_async(self.logsDispatchQueue, ^{
      [channel suspend];
    });
  }
}

- (void)resume {

  // Resume sender, logs can be sent again. Pending logs are sent.
  [self.sender setEnabled:YES andDeleteDataOnDisabled:NO];

  // Resume each channel asynchronously.
  for (id<MSChannelProtocol> channel in self.channels) {
    dispatch_async(self.logsDispatchQueue, ^{
      [channel resume];
    });
  }
}

#pragma mark - MSSenderDelegate

- (void)senderDidSuspend:(id<MSSender>)sender {
  (void)sender;
  [self suspend];
}

- (void)senderDidResume:(id<MSSender>)sender {
  (void)sender;
  [self resume];
}

- (void)senderDidReceiveFatalError:(id<MSSender>)sender {
  (void)sender;

  // Disable and delete data on fatal errors.
  [self setEnabled:NO andDeleteDataOnDisabled:YES];
}

#pragma mark - Other public methods

- (void)setLogUrl:(NSString *)logUrl {
  self.sender.baseURL = logUrl;
}

@end

