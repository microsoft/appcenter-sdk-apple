#import "AVAStorageBucket.h"

@implementation AVAStorageBucket

- (instancetype)init {
  if (self = [super init]) {
    _availableFiles = [NSMutableArray new];
    _blockedFiles = [NSMutableArray new];
  }
  return self;
}

@end
