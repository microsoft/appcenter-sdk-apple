#import <Foundation/Foundation.h>

#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityStringFormattingCategory;

/**
 * Utility class that is used throughout the SDK.
 * StringFormatting part.
 */
@interface MSUtility (StringFormatting)

/**
 * Create SHA256 of a string.
 *
 * @param string A string.
 *
 * @returns The SHA256 of given string.
 */
+ (NSString *)sha256:(NSString *)string;

/**
 * Extract app secret from a string.
 *
 * @param string A string.
 *
 * @returns The app secret or nil if none was found.
 */
+ (NSString *)appSecretFrom:(NSString *)string;

/**
 * Extract transmission target token from a string.
 *
 * @param string A string.
 *
 * @returns The tenant id or nil if none was found.
 */
+ (NSString *)transmissionTargetTokenFrom:(NSString *)string;

/**
 * Extract iKey from a transmission target token string.
 *
 * @param token The transmission target token as a string.
 *
 * @returns The iKey or nil if none was found.
 */
+ (nullable NSString *)iKeyFromTargetToken:(nullable NSString *)token;

/**
 * Extract target key from a transmission target token string.
 *
 * @param token The transmission target token as a string.
 *
 * @returns The target key or nil if none was found.
 */
+ (nullable NSString *)targetKeyFromTargetToken:(NSString *)token;

/**
 * Pretty print json data payload.
 *
 * @param data A data payload.
 *
 * @returns The pretty printed json data payload.
 */
+ (nullable NSString *)prettyPrintJson:(nullable NSData *)data;

@end

NS_ASSUME_NONNULL_END
