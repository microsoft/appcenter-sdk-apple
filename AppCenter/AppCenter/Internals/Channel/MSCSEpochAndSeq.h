#import <Foundation/Foundation.h>

@interface MSCSEpochAndSeq : NSObject

@property(nonatomic) NSUInteger seq;
@property(nonatomic) NSString *epoch;

/**
 * Create a MSCSEpochAndSeq with the given epoch.
 *
 * @param epoch The random unique UUID.
 *
 * @return A MSCSEpochAndSeq with the given epoch and default seq to 0.
 */
- (instancetype)initWithEpoch:(NSString *)epoch;

@end
