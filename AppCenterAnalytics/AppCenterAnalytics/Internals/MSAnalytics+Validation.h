#import "MSAnalyticsInternal.h"

@class MSCommonSchemaLog;
@class MSLogWithNameAndProperties;

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
- (BOOL)validateLog:(MSLogWithNameAndProperties *)log;

/**
 * Validate event name
 *
 * @return YES if event name is valid; NO otherwise.
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

/**
 * Validate MSEventProperties for App Center's ingestion.
 *
 * @return MSEventProperties object which contains only valid properties.
 */
- (MSEventProperties *)validateAppCenterEventProperties:(MSEventProperties *)properties;

@end

NS_ASSUME_NONNULL_END
