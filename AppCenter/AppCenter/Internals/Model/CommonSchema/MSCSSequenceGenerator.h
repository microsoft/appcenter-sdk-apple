#import <Foundation/Foundation.h>

@interface MSCSSequence : NSObject
- (NSUInteger)nextValue;
@end

@interface MSCSSequenceGenerator : NSObject
+ (MSCSSequence *)sequenceForTenant:(NSString *)tenant;
+ (void)reset;
@end
