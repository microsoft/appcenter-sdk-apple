#import "MSUtility+Date.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityDateCategory;

@implementation MSUtility (Date)

+ (NSTimeInterval)nowInMilliseconds {
    return ([[NSDate date] timeIntervalSince1970] * 1000);
}

@end
