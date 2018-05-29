#import <Foundation/Foundation.h>

@class MSCommonSchemaLog;

@protocol MSLogConversion

// TODO comment.
- (NSArray<MSCommonSchemaLog *> *)toCommonSchemaLogs

@end
