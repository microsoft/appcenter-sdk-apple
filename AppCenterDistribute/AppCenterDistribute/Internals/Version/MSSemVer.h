#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSSemVer : NSObject

/**
 * Base part of the version.
 */
@property(readonly) NSString *base;

/**
 * Pre-release part of the version.
 */
@property(nullable, readonly) NSString *preRelease;

/**
 * Metadata part of the version.
 */
@property(nullable, readonly) NSString *metadata;

/**
 * Initialize a semantic versioning object by parsing a version in string form.
 *
 * @param version A string representing a version.
 *
 * @return An instance of a semantic versioning object.
 */
- (instancetype)initWithString:(nullable NSString *)version;

/**
 * Allocate and initialize a semantic versioning object by parsing a version in string form.
 *
 * @param version A string representing a version.
 *
 * @return An instance of a semantic versioning object.
 */
+ (instancetype)semVerWithString:(nullable NSString *)version;

/**
 * Compare two versions.
 *
 * @param version A version to compare.
 *
 * @return The result of this comparison.
 */
- (NSComparisonResult)compare:(MSSemVer *)version;

/**
 * Check whether the given string is conform to semantic versioning format or not.
 *
 * @param version A version to check.
 *
 * @return `YES` if the given string is a valid non nil version conforming semantic versioning, `No` otherwise.
 */
+ (BOOL)isSemVerFormat:(nullable NSString *)version;

@end

NS_ASSUME_NONNULL_END
