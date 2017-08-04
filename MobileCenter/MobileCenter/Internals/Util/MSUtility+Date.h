#import <Foundation/Foundation.h>
#import "MSUtility.h"

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityDateCategory;

/**
 * Utility class that is used throughout the SDK.
 * Date part.
 */
@interface MSUtility (Date)

/**
 * Return the current date (aka NOW) in ms.
 *
 * @return current time in ms with sub-ms precision if necessary
 *
 * @discussion
 * Utility function that returns NOW as a NSTimeInterval but in ms instead of seconds with sub-ms precision. We're using NSTimeInterval
 * here instead of long long because we might be interested in sub-millisecond precision which we keep with NSTimeInterval as NSTimeInterval
 * is actually NSDouble.
 */
+ (NSTimeInterval)nowInMilliseconds;

@end
