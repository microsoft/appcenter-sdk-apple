#import "MSEventFilter.h"

// Singleton.
static MSEventFilter *sharedInstance = nil;
static dispatch_once_t onceToken;

// Event log type name.
static NSString *const kMSEventTypeName = @"event";

@implementation MSEventFilter

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)logTag {
  return @"EventFilter";
}

+ (NSString *)serviceName {
  return @"EventFilter";
}

- (NSString *)groupId {
  return @"eventFilter";
}

#pragma mark - MSServiceAbstract

/**
 * Enable/disable this service.
 *
 * @param isEnabled whether this service is enabled or not.
 *
 * @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];
  if (isEnabled) {
    [MSEventFilter logMessage:@"Event Filter service has been enabled." withLogLevel:MSLogLevelInfo];
  } else {
    [MSEventFilter logMessage:@"Event Filter service has been disabled." withLogLevel:MSLogLevelInfo];
  }
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(NSString *)appSecret
      transmissionTargetToken:(NSString *)token {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:YES];
  [channelGroup addDelegate:self];
}

#pragma mark - MSChannelDelegate

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)__unused channelUnit shouldFilterLog:(id<MSLog>)log {
  if (![MSEventFilter isEnabled]) {
    return NO;
  }
  if ([[log type] isEqualToString:kMSEventTypeName]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-YYYY HH:mm:ss"];
    NSString *logTimestampString = [dateFormatter stringFromDate:log.timestamp];
    NSString *message = [NSString stringWithFormat:@"Filtering out an event log. Details:\
                         \n\tLog Type = %@\
                         \n\tLog Timestamp = %@\
                         \n\tLog SID = %@\
                         \n\tEvent name = %@",
                                                   log.type, logTimestampString, log.sid, eventLog.name];
    [MSEventFilter logMessage:message withLogLevel:MSLogLevelInfo];
    return YES;
  }
  return NO;
}

#pragma mark - Helper methods

+ (void)logMessage:(NSString *)message withLogLevel:(MSLogLevel)logLevel {
  [MSWrapperLogger MSWrapperLog:^{
    return message;
  }
                            tag:[MSEventFilter logTag]
                          level:logLevel];
}

@end
