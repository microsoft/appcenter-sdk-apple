#import "MSAbstractLog.h"
#import "MSLog.h"
#import "MSSerializableObject.h"

@interface MSAbstractLog () <MSLog, MSSerializableObject>

/**
 * Serialize logs into a JSON string.
 *
 * @param prettyPrint boolean indicates pretty printing.
 *
 * @return A serialized string.
 */
- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint;

@end
