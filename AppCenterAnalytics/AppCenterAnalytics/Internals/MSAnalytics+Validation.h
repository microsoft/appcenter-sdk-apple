#import "MSAnalyticsInternal.h"

@class MSLogWithNameAndProperties;

@interface MSAnalytics (Validation)

- (BOOL)validateLog:(MSLogWithNameAndProperties *)log;

/**
 * Validate event name
 *
 * @return YES if event name is valid, NO otherwise.
 */
- (nullable NSString *)validateEventName:(NSString *)eventName forLogType:(NSString *)logType;

/**
 * Validate keys and values of properties. Intended for testing. Uses MSUtility+PropertyValidation internally.
 *
 * @return dictionary which contains only valid properties.
 */
- (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                     andType:(NSString *)logType;

@end
