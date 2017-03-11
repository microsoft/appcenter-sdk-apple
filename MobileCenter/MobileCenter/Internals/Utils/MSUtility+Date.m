#import "MSUtility+Date.h"

@implementation MSUtility (Date)

+ (NSTimeInterval)nowInMilliseconds {
    return ([[NSDate date] timeIntervalSince1970] * 1000);
}

@end
