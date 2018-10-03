#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class represents a pre-release identifier from a semantic versioning version.
 */
@interface MSSemVerPreReleaseId : NSObject

/**
 * Raw identifier as a string.
 */
@property(readonly) NSString *identifier;

/**
 * Allocate and initialize a semantic versioning pre-release identifier object by parsing an identifier in string form.
 *
 * @param identifier A string representing a pre-release identifier.
 *
 * @return An instance of a semantic versioning pre-release identifier object.
 */
+ (instancetype)identifierWithString:(NSString *)identifier;

/**
 * Initialize a semantic versioning pre-release identifier object by parsing an identifier in string form.
 *
 * @param identifier A string representing a pre-release identifier.
 *
 * @return An instance of a semantic versioning pre-release identifier object.
 */
- (instancetype)initWithString:(NSString *)identifier;

/**
 * Compare two pre-release identifiers.
 *
 * @param identifier A pre-release identifier to compare.
 *
 * @return The result of this comparison.
 */
- (NSComparisonResult)compare:(MSSemVerPreReleaseId *)identifier;

/**
 * Try to parse this identifier to a number. Returns `nil` if parsing failed.
 *
 * @return This identifier as a number or `nil` if parsing failed.
 */
- (nullable NSNumber *)numberValue;

@end

NS_ASSUME_NONNULL_END
