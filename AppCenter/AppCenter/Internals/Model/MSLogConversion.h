#import <Foundation/Foundation.h>

@class MSCommonSchemaLog;

@protocol MSLogConversion

/**
 * Method to transform a log into one or several common schema logs. Why several? This is because there can be nested transmission
 * targets so one log can actually transform into multiple logs, hence this method returns an array of MSCommonSchemaLog objects.
 *
 * @param flags The Common Schema flags for the log.
 *
 * @return An array of MCSCommonSchemaLog objects.
 */
- (NSArray<MSCommonSchemaLog *> *)toCommonSchemaLogsWithFlags:(int64_t)flags;

@end
