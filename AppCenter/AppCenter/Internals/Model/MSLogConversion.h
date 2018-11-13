#import <Foundation/Foundation.h>

#import "MSConstants+Flags.h"

@class MSCommonSchemaLog;

@protocol MSLogConversion

/**
 * Method to transform a log into one or several common schema logs. If the log has multiple transmission target tokens, the conversion will
 * produce one log per token.
 *
 * @param flags The Common Schema flags for the log.
 *
 * @return An array of MCSCommonSchemaLog objects.
 */
- (NSArray<MSCommonSchemaLog *> *)toCommonSchemaLogsWithFlags:(MSFlags)flags;

@end
