// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAbstractLog.h"
#import "MSAppCenterInternal.h"
#import "MSCommonSchemaLog.h"
#import "MSConstants.h"
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

#define MSLOG_VALIDATE(fieldName, rule)                                                                                                    \
  ({                                                                                                                                       \
    BOOL isValid = rule;                                                                                                                   \
    if (!isValid) {                                                                                                                        \
      MSLogVerbose([MSAppCenter logTag], @"%@: \"%@\" is not valid.", NSStringFromClass([self class]), @ #fieldName);                      \
    }                                                                                                                                      \
    isValid;                                                                                                                               \
  })

#define MSLOG_VALIDATE_NOT_NIL(fieldName) MSLOG_VALIDATE(fieldName, self.fieldName != nil)
