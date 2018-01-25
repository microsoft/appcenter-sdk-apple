#import <AppCenter/MSServiceAbstract.h>
#import <AppCenter/MSLog.h>
#import <AppCenter/MSLogger.h>
#import <AppCenter/MSChannelGroupProtocol.h>
#import <AppCenterAnalytics/MSEventLog.h>

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
 *  Enable/disable this service.
 *
 *  @param isEnabled whether this service is enabled or not.
 *  @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];
  if (isEnabled) {
    MSLogInfo([MSEventFilter logTag], @"Event Filter service has been enabled.");
  } else {
    MSLogInfo([MSEventFilter logTag], @"Event Filter service has been disabled.");
  }
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup appSecret:(NSString *)appSecret {
  [super startWithChannelGroup:channelGroup appSecret:appSecret];
  [channelGroup addDelegate:self];
}

#pragma mark - MSChannelDelegate

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  if (![MSEventFilter isEnabled]) {
    return NO;
  }
  if ([[log type] isEqualToString:kMSEventTypeName]) {
    MSEventLog *eventLog = (MSEventLog*)log;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-YYYY HH:mm:ss"];
    NSString *logTimestampString = [dateFormatter stringFromDate:log.timestamp];
    MSLogInfo([MSEventFilter logTag], @"Filtering out an event log. Details:\n\tLog Type = %@\n\tLog Timestamp = %@\n\tLog SID = %@\n\tEvent name = %@",  log.type, logTimestampString, log.sid, eventLog.name);
    return YES;
  }
  return NO;
}

@end

