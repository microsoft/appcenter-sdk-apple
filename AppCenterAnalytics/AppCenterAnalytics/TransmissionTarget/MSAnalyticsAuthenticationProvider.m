#import "MSAnalyticsAuthenticationProvider.h"
#import "MSAnalyticsAuthenticationProviderDelegate.h"
#import "MSAnalyticsInternal.h"
#import "MSLogger.h"
#import "MSTicketCache.h"
#import "MSUtility+StringFormatting.h"

// Number of seconds to refresh token before it expires.
static int kMSRefreshThreshold = 10 * 60;

@interface MSAnalyticsAuthenticationProvider ()

@property(nonatomic) NSDate *expiryDate;

/**
 * Completion block that will be used to get an updated authentication token.
 */
@property(nonatomic, copy) MSAnalyticsAuthenticationProviderCompletionBlock completionHandler;

@end

@implementation MSAnalyticsAuthenticationProvider

- (instancetype)initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                                  delegate:(id<MSAnalyticsAuthenticationProviderDelegate>)delegate {
  if ((self = [super init])) {
    _type = type;
    _ticketKey = ticketKey;
    if (ticketKey) {
      _ticketKeyHash = [MSUtility sha256:ticketKey];
    }
    _delegate = delegate;
  }
  return self;
}

- (void)acquireTokenAsync {
  id<MSAnalyticsAuthenticationProviderDelegate> strongDelegate = self.delegate;
  if (strongDelegate) {
    if (!self.completionHandler) {
      MSAnalyticsAuthenticationProvider *__weak weakSelf = self;
      self.completionHandler = ^void(NSString *token, NSDate *expiryDate) {
        MSAnalyticsAuthenticationProvider *strongSelf = weakSelf;
        [strongSelf handleTokenUpdateWithToken:token expiryDate:expiryDate withCompletionHandler:strongSelf.completionHandler];
      };
      [strongDelegate authenticationProvider:self acquireTokenWithCompletionHandler:self.completionHandler];
    }
  } else {
    MSLogError([MSAnalytics logTag], @"No completionhandler to acquire token has been set.");
  }
}

- (void)handleTokenUpdateWithToken:(NSString *)token
                        expiryDate:(NSDate *)expiryDate
             withCompletionHandler:(MSAnalyticsAuthenticationProviderCompletionBlock)completionHandler {
  @synchronized(self) {
    if (self.completionHandler == completionHandler) {
      self.completionHandler = nil;
      MSLogDebug([MSAnalytics logTag], @"Got result back from MSAcquireTokenCompletionBlock.");
      if (!token) {
        MSLogError([MSAnalytics logTag], @"Token must not be null");
        return;
      }
      if (!expiryDate) {
        MSLogError([MSAnalytics logTag], @"Date must not be null");
        return;
      }
      NSString *tokenPrefix;
      switch (self.type) {
      case MSAnalyticsAuthenticationTypeMsaCompact:
        tokenPrefix = @"p";
        break;
      case MSAnalyticsAuthenticationTypeMsaDelegate:
        tokenPrefix = @"d";
        break;
      }
      [[MSTicketCache sharedInstance] setTicket:[NSString stringWithFormat:@"%@:%@", tokenPrefix, token] forKey:self.ticketKeyHash];
      self.expiryDate = expiryDate;
    }
  }
}

- (void)checkTokenExpiry {
  @synchronized(self) {
    if (self.expiryDate &&
        (long long)[self.expiryDate timeIntervalSince1970] <= ((long long)[[NSDate date] timeIntervalSince1970] + kMSRefreshThreshold)) {
      [self acquireTokenAsync];
    }
  }
}

@end
