#import <Foundation/Foundation.h>
#import "MSIngestionHttpSender.h"

@implementation MSIngestionHttpSender

- (NSArray *)retryIntervals {

  // Call's retry intervals are: 10 sec, 5 min, 20 min.
  return @[@(10), @(5 * 60), @(20 * 60)];
}

- (NSString *)apiPath {
  return @"/logs";
}

@end
