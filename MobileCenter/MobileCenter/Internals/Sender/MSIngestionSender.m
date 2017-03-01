#import "MSIngestionSender.h"
#import "MobileCenter.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSHttpSenderPrivate.h"

@implementation MSIngestionSender

static NSString *const kMSApiPath = @"/logs";

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals {
  self = [super initWithBaseUrl:baseUrl
                        apiPath:kMSApiPath
                        headers:headers
                   queryStrings:queryStrings
                   reachability:reachability
                 retryIntervals:retryIntervals];
  return self;
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  MSLogContainer *container = (MSLogContainer *)data;
  NSString *batchId = container.batchId;

  // Verify container.
  if (!container || ![container isValid]) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : kMSMCLogInvalidContainerErrorDesc};
    NSError *error =
        [NSError errorWithDomain:kMSMCErrorDomain code:kMSMCLogInvalidContainerErrorCode userInfo:userInfo];
    MSLogError([MSMobileCenter logTag], @"%@", [error localizedDescription]);
    handler(batchId, error, nil);
    return;
  }

  [super sendAsync:container callId:container.batchId completionHandler:handler];
}

- (NSURLRequest *)createRequest:(NSObject *)data {
  MSLogContainer *container = (MSLogContainer *)data;
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"POST";

  // Set Header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  NSString *jsonString = [container serializeLog];
  request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't loose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSMobileCenter logTag], @"URL: %@", request.URL);
    MSLogVerbose([MSMobileCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }

  return request;
}

@end
