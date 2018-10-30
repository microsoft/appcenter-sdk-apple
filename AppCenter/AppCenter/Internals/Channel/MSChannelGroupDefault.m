#import "MSChannelGroupDefault.h"
#import "AppCenter+Internal.h"
#import "MSAppCenterIngestion.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSLogDBStorage.h"

static char *const kMSlogsDispatchQueue = "com.microsoft.appcenter.ChannelGroupQueue";

@implementation MSChannelGroupDefault

#pragma mark - Initialization

- (instancetype)initWithInstallId:(NSUUID *)installId logUrl:(NSString *)logUrl {
  self = [self initWithIngestion:[[MSAppCenterIngestion alloc] initWithBaseUrl:logUrl installId:[installId UUIDString]]];
  return self;
}

- (instancetype)initWithIngestion:(nullable MSAppCenterIngestion *)ingestion {
  if ((self = [self init])) {
    dispatch_queue_t serialQueue = dispatch_queue_create(kMSlogsDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _logsDispatchQueue = serialQueue;
    _channels = [NSMutableArray<id<MSChannelUnitProtocol>> new];
    _delegates = [NSHashTable weakObjectsHashTable];
    _ingestion = ingestion;
    _storage = [MSLogDBStorage new];
  }
  return self;
}

- (id<MSChannelUnitProtocol>)addChannelUnitWithConfiguration:(MSChannelUnitConfiguration *)configuration {
  return [self addChannelUnitWithConfiguration:configuration withIngestion:self.ingestion];
}

- (id<MSChannelUnitProtocol>)addChannelUnitWithConfiguration:(MSChannelUnitConfiguration *)configuration
                                               withIngestion:(nullable id<MSIngestionProtocol>)ingestion {
  MSChannelUnitDefault *channel;
  if (configuration) {
    channel = [[MSChannelUnitDefault alloc] initWithIngestion:(ingestion ? ingestion : self.ingestion)
                                                      storage:self.storage
                                                configuration:configuration
                                            logsDispatchQueue:self.logsDispatchQueue];
    [channel addDelegate:self];
    dispatch_async(self.logsDispatchQueue, ^{
      [channel flushQueue];
    });
    [self.channels addObject:channel];
    [self enumerateDelegatesForSelector:@selector(channelGroup:didAddChannelUnit:)
                              withBlock:^(id<MSChannelDelegate> channelDelegate) {
                                [channelDelegate channelGroup:self didAddChannelUnit:channel];
                              }];
  }
  return channel;
}

- (id<MSChannelUnitProtocol>)channelUnitForGroupId:(NSString *)groupId {
  for (MSChannelUnitDefault *channel in self.channels) {
    if ([channel.configuration.groupId isEqualToString:groupId]) {
      return channel;
    }
  }
  return nil;
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
  NSArray *synchronizedDelegates;
  @synchronized(self) {

    // Don't execute the block while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
  }
  for (id<MSChannelDelegate> delegate in synchronizedDelegates) {
    if (delegate && [delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

#pragma mark - Channel Delegate

- (void)channel:(id<MSChannelProtocol>)channel prepareLog:(id<MSLog>)log {
  [self enumerateDelegatesForSelector:@selector(channel:prepareLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel prepareLog:log];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didPrepareLog:(id<MSLog>)log internalId:(NSString *)internalId flags:(MSFlags)flags {
  [self enumerateDelegatesForSelector:@selector(channel:didPrepareLog:internalId:flags:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didPrepareLog:log internalId:internalId flags:flags];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didCompleteEnqueueingLog:(id<MSLog>)log internalId:(NSString *)internalId {
  [self enumerateDelegatesForSelector:@selector(channel:didCompleteEnqueueingLog:internalId:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didCompleteEnqueueingLog:log internalId:internalId];
                            }];
}

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

- (void)channel:(id<MSChannelProtocol>)channel didSetEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deletedData {
  [self enumerateDelegatesForSelector:@selector(channel:didSetEnabled:andDeleteDataOnDisabled:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didSetEnabled:isEnabled andDeleteDataOnDisabled:deletedData];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  [self enumerateDelegatesForSelector:@selector(channel:didFailSendingLog:withError:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didFailSendingLog:log withError:error];
                            }];
}

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)channelUnit shouldFilterLog:(id<MSLog>)log {
  __block BOOL shouldFilter = NO;
  [self enumerateDelegatesForSelector:@selector(channelUnit:shouldFilterLog:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              shouldFilter = shouldFilter || [delegate channelUnit:channelUnit shouldFilterLog:log];
                            }];
  return shouldFilter;
}

- (void)channel:(id<MSChannelProtocol>)channel didPauseWithIdentifyingObject:(id<NSObject>)identifyingObject {
  [self enumerateDelegatesForSelector:@selector(channel:didPauseWithIdentifyingObject:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didPauseWithIdentifyingObject:identifyingObject];
                            }];
}

- (void)channel:(id<MSChannelProtocol>)channel didResumeWithIdentifyingObject:(id<NSObject>)identifyingObject {
  [self enumerateDelegatesForSelector:@selector(channel:didResumeWithIdentifyingObject:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:channel didResumeWithIdentifyingObject:identifyingObject];
                            }];
}

#pragma mark - Enable / Disable

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {

  // Propagate to ingestion.
  [self.ingestion setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];

  // Propagate to initialized channels.
  for (id<MSChannelProtocol> channel in self.channels) {
    [channel setEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
  }

  // Notify delegates.
  [self enumerateDelegatesForSelector:@selector(channel:didSetEnabled:andDeleteDataOnDisabled:)
                            withBlock:^(id<MSChannelDelegate> delegate) {
                              [delegate channel:self didSetEnabled:isEnabled andDeleteDataOnDisabled:deleteData];
                            }];

  /**
   * TODO: There should be some concept of logs on disk expiring to avoid leaks when a channel is disabled with lingering logs but never
   * enabled again.
   *
   * Note that this is an unlikely scenario. Solving this issue is more of a proactive measure.
   */
}

#pragma mark - Pause / Resume

- (void)pauseWithIdentifyingObject:(id<NSObject>)identifyingObject {

  // Disable ingestion, sending log will not be possible but they'll still be stored.
  [self.ingestion setEnabled:NO andDeleteDataOnDisabled:NO];

  // Pause each channel asynchronously.
  for (id<MSChannelProtocol> channel in self.channels) {
    [channel pauseWithIdentifyingObject:identifyingObject];
  }
}

- (void)resumeWithIdentifyingObject:(id<NSObject>)identifyingObject {

  // Resume ingestion, logs can be sent again. Pending logs are sent.
  [self.ingestion setEnabled:YES andDeleteDataOnDisabled:NO];

  // Resume each channel asynchronously.
  for (id<MSChannelProtocol> channel in self.channels) {
    [channel resumeWithIdentifyingObject:identifyingObject];
  }
}

#pragma mark - Other public methods

- (void)setLogUrl:(NSString *)logUrl {
  self.ingestion.baseURL = logUrl;
}

- (void)setAppSecret:(NSString *)appSecret {
  self.ingestion.appSecret = appSecret;
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler {
  dispatch_async(self.logsDispatchQueue, ^{
    [self.storage setMaxStorageSize:sizeInBytes completionHandler:completionHandler];
  });
}

@end
