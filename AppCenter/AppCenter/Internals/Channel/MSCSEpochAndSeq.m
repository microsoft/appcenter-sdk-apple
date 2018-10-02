#import "MSCSEpochAndSeq.h"

@implementation MSCSEpochAndSeq

- (instancetype)initWithEpoch:(NSString *)epoch {
  if ((self = [super init])) {
    _epoch = epoch;
    _seq = 0;
  }
  return self;
}

@end
