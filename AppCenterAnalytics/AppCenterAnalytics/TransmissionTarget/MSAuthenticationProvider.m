#import "MSAuthenticationProvider.h"

#import "MSTicketCache.h"
#import "MSTokenProvider.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAuthenticationProvider

- (instancetype)initWithAuthenticationType:(MSAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                             tokenProvider:(id<MSTokenProvider>)tokenProvider {
  if ((self = [super init])) {
    _type = type;
    _ticketKey = ticketKey;
    if(_ticketKey) {
      _ticketKeyHash = [MSUtility sha256:ticketKey];
    }
    _tokenProvider = tokenProvider;
  }
  return self;
}

- (void)acquireTokenAsync {
  MSAuthenticationProvider* __weak weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    MSAuthenticationProvider *strongSelf = weakSelf;
    
    [strongSelf.tokenProvider authenticationProvider:strongSelf getTokenFor:strongSelf.ticketKey withCompletionBlock:^(NSString * token){
      [[MSTicketCache sharedInstance] setTicket:token forKey:strongSelf.ticketKeyHash];
    }];
  });
}

@end
