#import "MSAnalyticsAuthenticationResult.h"

@implementation MSAnalyticsAuthenticationResult

- (instancetype)initWithToken:(NSString *)token expiryDate:(NSDate *)expiryDate {
  self = [super init];
  if (self) {
    _token = [token copy];
    _expiryDate = expiryDate;
  }

  return self;
}

@end