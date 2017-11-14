#import <Foundation/Foundation.h>

#import "MSLog.h"

@interface MSLogContainer : NSObject

/**
 * Unique batch Id.
 */
@property(nonatomic, copy) NSString *batchId;

/**
 * The list of logs
 */
@property(nonatomic) NSArray<id<MSLog>> *logs;

/**
 * Initializer.
 *
 * @param batchId Unique batch ID.
 * @param logs Array of logs.
 *
 * @return A log container instance for the given batch ID.
 */
- (id)initWithBatchId:(NSString *)batchId andLogs:(NSArray<id<MSLog>> *)logs;

/**
 * Serialize logs into a JSON string.
 *
 * @return A JSON string.
 */
- (NSString *)serializeLog;

/**
 * Serialize logs into a JSON string.
 *
 * @param prettyPrint boolean indicates pretty printing.
 *
 * @return A serialized string.
 */
- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
