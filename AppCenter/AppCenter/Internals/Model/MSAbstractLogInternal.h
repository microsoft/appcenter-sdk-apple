// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAbstractLog.h"
#import "MSConstants.h"
#import "MSLog.h"
#import "MSLogConversion.h"
#import "MSSerializableObject.h"

@class MSCommonSchemaLog;

@interface MSAbstractLog () <MSLog, MSSerializableObject, MSLogConversion>

/**
 * Serialize logs into a JSON string.
 *
 * @param prettyPrint boolean indicates pretty printing.
 *
 * @return A serialized string.
 */
- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint;

/**
 * Convert an AppCenter log to the Common Schema 3.0 event log per tenant token.
 *
 * @param token The tenant token.
 * @param flags Flags to set for the common schema log.
 *
 * @return A common schema log.
 */
- (MSCommonSchemaLog *)toCommonSchemaLogForTargetToken:(NSString *)token flags:(MSFlags)flags;

@end
