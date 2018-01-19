#import <AppCenter/MSServiceAbstract.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Log filtering service.
 */
@interface MSLogFilter : MSServiceAbstract

/**
 * Filter out a log type.
 *
 * @param logType  log type.
 */
+ (void)filterLogType:(NSString *)logType;

/**
 * Unfilter a log type.
 *
 * @param logType  log type.
 */
+ (void)unfilterLogType:(NSString *)logType;

/**
 * Determines whether a log type is being filtered.
 *
 * @param logType  log type.
 */
+ (BOOL)isFilteringLogType:(NSString *)logType;

@end

NS_ASSUME_NONNULL_END

