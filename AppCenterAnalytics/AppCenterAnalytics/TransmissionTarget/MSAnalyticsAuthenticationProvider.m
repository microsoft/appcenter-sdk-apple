#import "MSAnalyticsAuthenticationProvider.h"

#import "MSAnalyticsInternal.h"
#import "MSLogger.h"
#import "MSTicketCache.h"
#import "MSUtility+StringFormatting.h"

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
    MSAnalyticsAuthenticationProvider *__weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      MSAnalyticsAuthenticationProvider *strongSelf = weakSelf;
      NSString *token = self.completionHandler();
      [[MSTicketCache sharedInstance] setTicket:token
                                         forKey:strongSelf.ticketKeyHash];
    });
  } else {
    MSLogError([MSAnalytics logTag],
               @"No completionhandler to acquire token has been set.");
  }
}

@end
