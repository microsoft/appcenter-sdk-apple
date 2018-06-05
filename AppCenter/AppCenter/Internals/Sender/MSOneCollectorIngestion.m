#import "MSAppCenterInternal.h"
#import "MSAppCenterErrors.h"
#import "MSConstants+Internal.h"
#import "MSHttpSenderPrivate.h"
#import "MSLog.h"
#import "MSLogContainer.h"
#import "MSLoggerInternal.h"
#import "MSOneCollectorIngestion.h"
#import "MSUtility+Date.h"

NSString *const kMSOneCollectorApiVersion = @"1.0";
NSString *const kMSOneCollectorApiPath = @"/OneCollector";
NSString *const kMSOneCollectorContentType = @"application/x-json-stream; charset=utf-8;";
NSString *const kMSOneCollectorApiKey = @"apikey";
NSString *const kMSOneCollectorClientVersionKey = @"Client-Version";
NSString *const kMSOneCollectorUploadTimeKey = @"Upload-Time";

@implementation MSOneCollectorIngestion

- (id)initWithBaseUrl:(NSString *)baseUrl {
  self = [super initWithBaseUrl:baseUrl
                        apiPath:[NSString stringWithFormat:@"%@/%@", kMSOneCollectorApiPath, kMSOneCollectorApiVersion]
                        headers:@{
                          kMSHeaderContentTypeKey : kMSOneCollectorContentType,
                          kMSOneCollectorClientVersionKey :
                              [NSString stringWithFormat:kMSOneCollectorClientVersionFormat, [MSUtility sdkVersion]]
                        }
                   queryStrings:nil
                   reachability:[MS_Reachability reachabilityForInternetConnection]
                 retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]
         maxNumberOfConnections:2];
  return self;
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  MSLogContainer *container = (MSLogContainer *)data;
  NSString *batchId = container.batchId;

  /*
   * FIXME: All logs are already validated at the time the logs are enqueued to Channel. It is not necessary but it can
   * still protect against invalid logs being sent to server that are messed up somehow in Storage. If we see
   * performance issues due to this validation, we will remove `[container isValid]` call below.
   */
  // Verify container.
  if (!container || ![container isValid]) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : kMSACLogInvalidContainerErrorDesc};
    NSError *error =
        [NSError errorWithDomain:kMSACErrorDomain code:kMSACLogInvalidContainerErrorCode userInfo:userInfo];
    MSLogError([MSAppCenter logTag], @"%@", [error localizedDescription]);
    handler(batchId, nil, nil, error);
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
  NSMutableDictionary *headers = [self.httpHeaders mutableCopy];
  NSMutableSet<NSString *> *apiKeys = [NSMutableSet new];
  for (id<MSLog> log in container.logs) {
    [apiKeys addObjectsFromArray:[log.transmissionTargetTokens allObjects]];
  }
  [headers setObject:[[apiKeys allObjects] componentsJoinedByString:@","] forKey:kMSOneCollectorApiKey];
  [headers setObject:[NSString stringWithFormat:@"%lld", (long long)[MSUtility nowInMilliseconds]]
              forKey:kMSOneCollectorUploadTimeKey];
  request.allHTTPHeaderFields = headers;

  // Set body.
  NSString *jsonString = [container serializeLog];
  request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't loose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", request.URL);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }
  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)key value:(NSString *)value {
  return [key isEqualToString:kMSOneCollectorApiKey] ? [self obfuscateTargetTokens:value] : value;
}

- (NSString *)obfuscateTargetTokens:(NSString *)tokenString {
  NSArray *tokens = [tokenString componentsSeparatedByString:@","];
  NSMutableArray *obfuscatedTokens = [NSMutableArray new];
  for (NSString *token in tokens) {
    [obfuscatedTokens addObject:[MSSenderUtil hideSecret:token]];
  }
  return [obfuscatedTokens componentsJoinedByString:@","];
}

@end
