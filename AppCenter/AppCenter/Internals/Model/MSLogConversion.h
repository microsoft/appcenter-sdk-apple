#import <Foundation/Foundation.h>

@class MSCommonSchemaLog;

@protocol MSLogConversion

/**
 * Keep track of common schema logs.
 */
- (NSArray<MSCommonSchemaLog *> *)toCommonSchemaLogs;

@end
