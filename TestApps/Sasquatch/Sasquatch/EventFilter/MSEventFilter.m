#import <AppCenterAnalytics/MSEventLog.h>

#import "MSEventFilter.h"
#import "MSLogManager.h"
#import "MSServiceAbstractProtected.h"
#import "MSServiceAbstractInternal.h"
#import "MSServiceCommon.h"
#import "MSServiceInternal.h"
#import "MSLog.h"
#import "MSLogManagerDelegate.h"
#import "MSLogger.h"

@interface MSEventFilter () <MSServiceInternal, MSLogManagerDelegate>

@end

// Singleton.
static MSEventFilter *sharedInstance = nil;
static dispatch_once_t onceToken;

// Service name for initialization.
static NSString *const kMSServiceName = @"EventFilter";

// Group id.
static NSString *const kMSGroupId = @"EventFilter";

// Event log type name.
static NSString *const kMSEventTypeName = @"event";

@implementation MSEventFilter

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
  MSLogVerbose([MSEventFilter logTag], @"Started Event Filter service.");
}

+ (NSString *)logTag {
  return @"EventFilter";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    // Add delegate to log manager.
    [self.logManager addDelegate:self];
    MSLogInfo([MSEventFilter logTag], @"Event Filter service has been enabled.");
  } else {
    [self.logManager removeDelegate:self];
      MSLogInfo([MSEventFilter logTag], @"Event Filter service has been disabled.");
  }
}

#pragma mark - Log Manager Delegate

- (BOOL)shouldFilterLog:(id<MSLog>)log {
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
