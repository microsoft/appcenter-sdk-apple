#import <Foundation/Foundation.h>

@interface MSCSSequence : NSObject
- (NSUInteger)nextValue;
@end

@interface MSCSSequenceGenerator : NSObject
+ (MSCSSequence *)sequenceForTargetToken:(NSString *)token;
+ (void)reset;
@end
