#import "MSDistributionGroup.h"

@implementation MSDistributionGroup

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSDistributionGroup class]]) {
    return NO;
  }
  return YES;
}

@end
