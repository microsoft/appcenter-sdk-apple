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

@end

NS_ASSUME_NONNULL_END
