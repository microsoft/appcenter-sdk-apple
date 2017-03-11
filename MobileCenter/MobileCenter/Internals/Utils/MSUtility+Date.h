#import <Foundation/Foundation.h>
#import "MSUtil.h"

/**
 * Utility class that is used throughout the SDK.
 */
@interface MSUtility (Date)

/**
 * Return the current date (aka NOW) in ms.
 *
 * @discussion
 * Utility function that returns NOW as a NSTimeInterval but in ms instead of seconds with sub-ms precision. We're using NSTimeInterval
 * here instead of long long because we might be interested in sub-millisecond precision which we keep with NSTimeInterval as NSTimeInterval
 * is actually NSDouble.
 *
 * @return current time in ms with sub-ms precision if necessary
 */
+ (NSTimeInterval)nowInMilliseconds;

@end
