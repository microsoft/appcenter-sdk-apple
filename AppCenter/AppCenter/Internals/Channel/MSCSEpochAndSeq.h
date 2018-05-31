#import <Foundation/Foundation.h>

@interface MSCSEpochAndSeq: NSObject

@property (nonatomic) NSUInteger seq;
@property (nonatomic) NSString *epoch;

// TODO comment
- (instancetype)initWithEpoch:(NSString *)epoch;

@end
