#import "MSAnalyticsInternal.h"

@class MSLogWithNameAndProperties;
@class MSCommonSchemaLog;

NS_ASSUME_NONNULL_BEGIN

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSAnalyticsValidationCategory;

@interface MSAnalytics (Validation)

/**
 * Validate AppCenter log.
 *
 * @param log The AppCenter log.
 *
 * @return YES if AppCenter log is valid; NO otherwise.
 */
- (BOOL)validateACLog:(MSLogWithNameAndProperties *)log;

/**
 * Validate event name
 *
 * @return YES if event name is valid; NO otherwise.
 */
- (nullable NSString *)validateACEventName:(NSString *)eventName forLogType:(NSString *)logType;

/**
 * Validate Common Schema 3.0 Log.
 *
 * @param log The Common Schema log.
 *
 * @return YES if Common Schema log is valid; NO otherwise.
 */
- (BOOL)validateCSLog:(MSCommonSchemaLog *)log;

/**
 * Validate the Common Schema event name.
 *
 * @param eventName The event name.
 *
 * @return YES if event name is valid, NO otherwise.
 */
- (BOOL)validateCSEventName:(nonnull NSString *)eventName;

/**
 * Validate keys and values of properties. Intended for testing. Uses MSUtility+PropertyValidation internally.
 *
 * @return dictionary which contains only valid properties.
 */
- (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                     andType:(NSString *)logType;

@end

NS_ASSUME_NONNULL_END
