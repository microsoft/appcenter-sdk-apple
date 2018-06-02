#import "AppCenter+Internal.h"
#import "MSAnalytics+Validation.h"
#import "MSCommonSchemaLog.h"
#import "MSEventLog.h"
#import "MSPageLog.h"

// Events values limitations
static const int minEventNameLength = 1;
static const int maxEventNameLength = 256;

// Alphanumeric characters, no heading or traling periods, no consecutive periods, no heading underscores, max length of
// 100.
static NSString *const kCSEventNameRegex = @"^[a-zA-Z0-9]((\\.(?!(\\.|$)))|[_a-zA-Z0-9]){0,99}$";

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSAnalyticsValidationCategory;

@implementation MSAnalytics (Validation)

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]]) {
    return ![self validateACLog:(MSEventLog *)log];
  } else if ([logObject isKindOfClass:[MSPageLog class]]) {
    return ![self validateACLog:(MSPageLog *)log];
  } else if ([logObject isKindOfClass:[MSCommonSchemaLog class]]) {
    return ![self validateCSLog:(MSCommonSchemaLog *)log];
  }
  return NO;
}

- (BOOL)validateACLog:(MSLogWithNameAndProperties *)log {

  // Validate event name.
  NSString *validName = [self validateACEventName:log.name forLogType:log.type];
  if (!validName) {
    return NO;
  }
  log.name = validName;

  // Send only valid properties.
  log.properties = [self validateProperties:log.properties forLogName:log.name andType:log.type];
  return YES;
}

- (nullable NSString *)validateACEventName:(NSString *)eventName forLogType:(NSString *)logType {
  if (!eventName || [eventName length] < minEventNameLength) {
    MSLogError([MSAnalytics logTag], @"%@ name cannot be null or empty", logType);
    return nil;
  }
  if ([eventName length] > maxEventNameLength) {
    MSLogWarning([MSAnalytics logTag],
                 @"%@ '%@' : name length cannot be longer than %d characters. Name will be truncated.", logType,
                 eventName, maxEventNameLength);
    eventName = [eventName substringToIndex:maxEventNameLength];
  }
  return eventName;
}

- (BOOL)validateCSLog:(MSCommonSchemaLog *)log {

  // Validate core fields
  if (![self validateCSEventName:log.name]) {
    MSLogError([MSAnalytics logTag], @"Invalid event name '%@'", log.name);
    return NO;
  }

  if (![self validateCSPopSample:log.popSample]) {
    MSLogError([MSAnalytics logTag], @"Invalid popSample '%f'", log.popSample);
    return NO;
  }

  // TODO Add Part C properties contraints.

  return [log isValid];
}

- (BOOL)validateCSEventName:(nonnull NSString *)eventName {
  if (!eventName || !eventName.length) {
    MSLogError([MSAnalytics logTag], @"Event name cannot be null or empty");
    return NO;
  }

  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kCSEventNameRegex
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
  NSRange range = NSMakeRange(0, eventName.length);
  if (regex) {
    NSUInteger count = [regex numberOfMatchesInString:eventName options:0 range:range];
    if (!count) {
      MSLogError([MSAnalytics logTag], @"Invalid event name '%@'", eventName);
      return NO;
    }
  }
  return YES;
}

- (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                     andType:(NSString *)logType {

  // Keeping this method body in MSAnalytics to use it in unit tests.
  return [MSUtility validateProperties:properties forLogName:logName type:logType];
}

#pragma mark - Helper

- (BOOL)validateCSPopSample:(double)popSample {
  return popSample >= 0 && popSample <= 100;
}

@end
