#import "MSAnalyticsAuthenticationProvider.h"

#import "MSTicketCache.h"
#import "MSAnalyticsAuthenticationProviderDelegate.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsAuthenticationProvider

- (instancetype)
initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                 ticketKey:(NSString *)ticketKey
                  delegate:(id<MSAnalyticsAuthenticationProviderDelegate>)delegate {
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

- (void)acquireTokenAsync {
  MSAnalyticsAuthenticationProvider *__weak weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    MSAnalyticsAuthenticationProvider *strongSelf = weakSelf;

    //TODO To be decided which callback to use.
    if ([strongSelf.delegate
            respondsToSelector:@selector(authenticationProvider:
                                                    getTokenFor:
                                              completionHandler:)]) {
      [strongSelf.delegate authenticationProvider:strongSelf
                                      getTokenFor:strongSelf.ticketKey
                                completionHandler:^(NSString *token) {
                                  [[MSTicketCache sharedInstance]
                                      setTicket:token
                                         forKey:strongSelf.ticketKeyHash];
                                }];
    } else {
      NSString *token =
          [strongSelf.delegate authenticationProvider:strongSelf
                                          getTokenFor:strongSelf.ticketKey];
      [[MSTicketCache sharedInstance] setTicket:token
                                         forKey:strongSelf.ticketKeyHash];
    }
  });
}

@end
