#import "AppCenter+Internal.h"
#import "MSAnalytics+Validation.h"
#import "MSCommonSchemaLog.h"
#import "MSEventLog.h"
#import "MSPageLog.h"

// Events values limitations
static const int kMSMinEventNameLength = 1;
static const int kMSMaxEventNameLength = 256;

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSAnalyticsValidationCategory;

@implementation MSAnalytics (Validation)

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)__unused channelUnit
    shouldFilterLog:(id<MSLog>)log {
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]]) {
    return ![self validateLog:(MSEventLog *)log];
  } else if ([logObject isKindOfClass:[MSPageLog class]]) {
    return ![self validateLog:(MSPageLog *)log];
  }
  return NO;
}

- (BOOL)validateLog:(MSLogWithNameAndProperties *)log {

  // Validate event name.
  NSString *validName = [self validateEventName:log.name forLogType:log.type];
  if (!validName) {
    return NO;
  }
  log.name = validName;

  // Send only valid properties.
  log.properties = [self validateProperties:log.properties
                                 forLogName:log.name
                                    andType:log.type];
  return YES;
}

- (nullable NSString *)validateEventName:(NSString *)eventName
                              forLogType:(NSString *)logType {
  if (!eventName || [eventName length] < kMSMinEventNameLength) {
    MSLogError([MSAnalytics logTag], @"%@ name cannot be null or empty",
               logType);
    return nil;
  }
  if ([eventName length] > kMSMaxEventNameLength) {
    MSLogWarning([MSAnalytics logTag],
                 @"%@ '%@' : name length cannot be longer than %d characters. "
                 @"Name will be truncated.",
                 logType, eventName, kMSMaxEventNameLength);
    eventName = [eventName substringToIndex:kMSMaxEventNameLength];
  }
  return eventName;
}

- (NSDictionary<NSString *, NSString *> *)
validateProperties:(NSDictionary<NSString *, NSString *> *)properties
        forLogName:(NSString *)logName
           andType:(NSString *)logType {

  // Keeping this method body in MSAnalytics to use it in unit tests.
  return
      [MSUtility validateProperties:properties forLogName:logName type:logType];
}
@end
