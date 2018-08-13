
#import "MSAnalyticsAuthenticationProvider.h"

#import "MSAnalyticsInternal.h"
#import "MSLogger.h"
#import "MSTicketCache.h"
#import "MSUtility+StringFormatting.h"
#import "MSAnalyticsAuthenticationResult.h"

static int kMSRefreshThreshold = 10 * 60;

@interface MSAnalyticsAuthenticationProvider ()

@property(nonatomic) BOOL isAlreadyAcquiringToken;

@property(nonatomic) NSDate *expiryDate;

@end

@implementation MSAnalyticsAuthenticationProvider

- (instancetype)initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                         completionHandler:
                             (MSAcquireTokenCompletionBlock)completionHandler {
  if ((self = [super init])) {
    _type = type;
    _ticketKey = ticketKey;
    if (ticketKey) {
      _ticketKeyHash = [MSUtility sha256:ticketKey];
    }
    _completionHandler = completionHandler;
  }
  return self;
}

- (void)acquireTokenAsync {
  if (self.completionHandler) {
    if (!self.isAlreadyAcquiringToken) {
      self.isAlreadyAcquiringToken = YES;
      MSAnalyticsAuthenticationProvider *__weak weakSelf = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        MSAnalyticsAuthenticationProvider *strongSelf = weakSelf;
        MSAnalyticsAuthenticationResult *result = self.completionHandler();
        strongSelf.isAlreadyAcquiringToken = NO;
        if (!result) {
          MSLogError([MSAnalytics logTag],
                     @"Result of authentication is null.");
        } else {
          [strongSelf handleTokenUpdateWithToken:result.token
                                      expiryDate:result.expiryDate];
        }
      });
    }
  } else {
    MSLogError([MSAnalytics logTag],
               @"No completionhandler to acquire token has been set.");
  }
}

- (void)handleTokenUpdateWithToken:(NSString *)token
                        expiryDate:(NSDate *)expiryDate {
  MSLogDebug([MSAnalytics logTag],
             @"Got result back from MSAcquireTokenCompletionBlock.");
  if (!token) {
    MSLogError([MSAnalytics logTag], @"Token must not be null");
  }
  if (!expiryDate) {
    MSLogError([MSAnalytics logTag], @"Date must not be null");
  }
  NSString *tokenPrefix = (self.type == MSAnalyticsAuthenticationTypeMsaCompact) ? @"p:" : @"d:";
  [[MSTicketCache sharedInstance] setTicket:[NSString stringWithFormat:@"%@%@", tokenPrefix, token] forKey:self.ticketKeyHash];
  self.expiryDate = expiryDate;
}

- (void)checkTokenExpiry {
  if (self.expiryDate &&
      (long long) [self.expiryDate timeIntervalSince1970] <=
          ((long long) [[NSDate date] timeIntervalSince1970] + kMSRefreshThreshold)) {
    [self acquireTokenAsync];
  }
}

@end
