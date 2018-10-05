#import <Foundation/Foundation.h>

#import "MSDistributionStartSessionLog.h"

static NSString *const kMSTypeDistributionStartSessionLog = @"distributionStartSession";

@implementation MSDistributionStartSessionLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeDistributionStartSessionLog;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

@end
