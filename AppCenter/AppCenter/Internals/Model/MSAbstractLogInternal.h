#import "MSAbstractLog.h"
#import "MSCommonSchemaLog.h"
#import "MSLog.h"
#import "MSLogConversion.h"
#import "MSSerializableObject.h"

@interface MSAbstractLog () <MSLog, MSSerializableObject, MSLogConversion>

/**
 * Serialize logs into a JSON string.
 *
 * @param prettyPrint boolean indicates pretty printing.
 *
 * @return A serialized string.
 */
- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint;

// TODO comment
- (MSCommonSchemaLog *)toCommonSchemaLogForTargetToken:(NSString *) token;
@end
