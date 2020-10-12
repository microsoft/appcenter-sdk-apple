// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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

- (BOOL)isAppSecretRequired {
  return NO;
}

#pragma mark - MSACServiceAbstract

/**
 *  Enable/disable this service.
 *
 *  @param isEnabled whether this service is enabled or not.
 *
 *  @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];
  if (isEnabled) {
    [MSEventFilter logMessage:@"Event Filter service has been enabled." withLogLevel:MSACLogLevelInfo];
  } else {
    [MSEventFilter logMessage:@"Event Filter service has been disabled." withLogLevel:MSACLogLevelInfo];
  }
}

- (void)startWithChannelGroup:(id<MSACChannelGroupProtocol>)channelGroup
                    appSecret:(NSString *)appSecret
      transmissionTargetToken:(NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  [channelGroup addDelegate:self];
}

#pragma mark - MSACChannelDelegate

- (BOOL)channelUnit:(id<MSACChannelUnitProtocol>)__unused channelUnit shouldFilterLog:(id<MSACLog>)log {
  if (![MSEventFilter isEnabled]) {
    return NO;
  }
  if ([[log type] isEqualToString:kMSEventTypeName]) {
    MSACEventLog *eventLog = (MSACEventLog *)log;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-YYYY HH:mm:ss"];
    NSString *logTimestampString = [dateFormatter stringFromDate:log.timestamp];
    NSString *message = [NSString stringWithFormat:@"Filtering out an event log. Details:\
                            \n\tLog Type = %@\
                            \n\tLog Timestamp = %@\
                            \n\tLog SID = %@\
                            \n\tEvent name = %@",
                                                   log.type, logTimestampString, log.sid, eventLog.name];
    [MSEventFilter logMessage:message withLogLevel:MSACLogLevelInfo];
    return YES;
  }
  return NO;
}

#pragma mark - Helper methods
+ (void)logMessage:(NSString *)message withLogLevel:(MSACLogLevel)logLevel {
  [MSACWrapperLogger MSACWrapperLog:^{
    return message;
  }
                            tag:[MSEventFilter logTag]
                          level:logLevel];
}

@end
