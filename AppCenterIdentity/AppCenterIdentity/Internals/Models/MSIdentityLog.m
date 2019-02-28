#import <Foundation/Foundation.h>

#import "MSIdentityLog.h"

static NSString *const kMSTypeIdentityLog = @"identityLog";

@implementation MSIdentityLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeIdentityLog;
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
