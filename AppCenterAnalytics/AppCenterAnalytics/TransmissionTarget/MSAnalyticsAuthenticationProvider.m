#import "MSAnalyticsAuthenticationProvider.h"

#import "MSTicketCache.h"
#import "MSAnalyticsAuthenticationProviderDelegate.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsAuthenticationProvider

- (instancetype)
initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                 ticketKey:(NSString *)ticketKey
                  delegate:
                      (id<MSAnalyticsAuthenticationProviderDelegate>)delegate {
  if ((self = [super init])) {
    _type = type;
    _ticketKey = ticketKey;
    if (_ticketKey) {
      _ticketKeyHash = [MSUtility sha256:ticketKey];
    }
    _delegate = delegate;
  }
  return self;
}

- (instancetype)initWithAuthenticationType:(MSAnalyticsAuthenticationType)type ticketKey:(NSString *)ticketKey completionHandler:(MSAcquireTokenCompletionBlock)completionHandler {
  if ((self = [super init])) {
    _type = type;
    _ticketKey = ticketKey;
    _ticketKeyHash = [MSUtility sha256:ticketKey];
    _completionHandler  = completionHandler;
  }
  return self;
}

- (void)acquireTokenAsync {
  MSAnalyticsAuthenticationProvider *__weak weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    MSAnalyticsAuthenticationProvider *strongSelf = weakSelf;

    // TODO To be decided which approach to use.
    NSString *token;
    if(strongSelf.completionHandler) {
      token = self.completionHandler();
    }
    else {
      token = [strongSelf.delegate
               tokenWithAuthenticationProvider:strongSelf
               ticketKey:strongSelf.ticketKey];
    }
    [[MSTicketCache sharedInstance] setTicket:token
                                       forKey:strongSelf.ticketKeyHash];
  });
}

@end
