// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAbstractLogInternal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSCSExtensions.h"
#import "MSConstants+Internal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSOneCollectorIngestionPrivate.h"
#import "MSProtocolExtension.h"
#import "MSTicketCache.h"
#import "MSUtility+StringFormatting.h"

@implementation MSOneCollectorIngestion

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient baseUrl:(NSString *)baseUrl {
  self = [super initWithHttpClient:httpClient
                           baseUrl:baseUrl
                           apiPath:[NSString stringWithFormat:@"%@/%@", kMSOneCollectorApiPath, kMSOneCollectorApiVersion]
                           headers:@{
                             kMSHeaderContentTypeKey : kMSOneCollectorContentType,
                             kMSOneCollectorClientVersionKey :
                                 [NSString stringWithFormat:kMSOneCollectorClientVersionFormat, [MSUtility sdkVersion]]
                           }
                      queryStrings:nil
                    retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]
            maxNumberOfConnections:2];
  return self;
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  MSLogContainer *container = (MSLogContainer *)data;
  NSString *batchId = container.batchId;

  /*
   * FIXME: All logs are already validated at the time the logs are enqueued to Channel. It is not necessary but it can still protect
   * against invalid logs being sent to server that are messed up somehow in Storage. If we see performance issues due to this validation,
   * we will remove `[container isValid]` call below.
   */

  // Verify container.
  if (!container || ![container isValid]) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : kMSACLogInvalidContainerErrorDesc};
    NSError *error = [NSError errorWithDomain:kMSACErrorDomain code:MSACLogInvalidContainerErrorCode userInfo:userInfo];
    MSLogError([MSAppCenter logTag], @"%@", [error localizedDescription]);
    handler(batchId, 0, nil, error);
    return;
  }
  [super sendAsync:container
      completionHandler:^(NSString *_Nonnull __unused callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable responseBody,
                          NSError *_Nullable error) {
        // Ignore the given call ID so that the container's batch ID can be used instead.
        handler(batchId, response, responseBody, error);
      }];
}

- (NSDictionary *)getHeadersWithData:(nullable NSObject *)data eTag:(nullable NSString *__unused)eTag {
  MSLogContainer *container = (MSLogContainer *)data;
  NSMutableDictionary *headers = [self.httpHeaders mutableCopy];
  NSMutableSet<NSString *> *apiKeys = [NSMutableSet new];
  for (id<MSLog> log in container.logs) {
    [apiKeys addObjectsFromArray:[log.transmissionTargetTokens allObjects]];
  }
  headers[kMSOneCollectorApiKey] = [[apiKeys allObjects] componentsJoinedByString:@","];
  headers[kMSOneCollectorUploadTimeKey] = [NSString stringWithFormat:@"%lld", (long long)[MSUtility nowInMilliseconds]];

  // Gather tokens from logs.
  NSMutableDictionary<NSString *, NSString *> *ticketsAndKeys = [NSMutableDictionary<NSString *, NSString *> new];
  for (id<MSLog> log in container.logs) {
    MSCommonSchemaLog *csLog = (MSCommonSchemaLog *)log;
    if (csLog.ext.protocolExt) {
      NSArray<NSString *> *ticketKeys = [[[csLog ext] protocolExt] ticketKeys];
      for (NSString *ticketKey in ticketKeys) {
        NSString *authenticationToken = [[MSTicketCache sharedInstance] ticketFor:ticketKey];
        if (authenticationToken) {
          [ticketsAndKeys setValue:authenticationToken forKey:ticketKey];
        }
      }
    }
  }
  if (ticketsAndKeys.count > 0) {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ticketsAndKeys options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [headers setValue:jsonString forKey:kMSOneCollectorTicketsKey];
  }

  return headers;
}

- (NSData *)getPayloadWithData:(nullable NSObject *)data {
  MSLogContainer *container = (MSLogContainer *)data;
  NSMutableString *jsonString = [NSMutableString new];
  for (id<MSLog> log in container.logs) {
    MSAbstractLog *abstractLog = (MSAbstractLog *)log;
    [jsonString appendString:[abstractLog serializeLogWithPrettyPrinting:NO]];

    // Separator for one collector logs.
    [jsonString appendString:kMSOneCollectorLogSeparator];
  }
  NSData *httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  return httpBody;
}

- (NSString *)obfuscateResponsePayload:(NSString *)payload {
  return [MSUtility obfuscateString:payload
                searchingForPattern:kMSTokenKeyValuePattern
              toReplaceWithTemplate:kMSTokenKeyValueObfuscatedTemplate];
}

- (NSString *)obfuscateTargetTokens:(NSString *)tokenString {
  NSArray *tokens = [tokenString componentsSeparatedByString:@","];
  NSMutableArray *obfuscatedTokens = [NSMutableArray new];
  for (NSString *token in tokens) {
    [obfuscatedTokens addObject:[MSHttpUtil hideSecret:token]];
  }
  return [obfuscatedTokens componentsJoinedByString:@","];
}

- (NSString *)obfuscateTickets:(NSString *)ticketString {
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@":[^\"]+" options:0 error:nil];
  return [regex stringByReplacingMatchesInString:ticketString options:0 range:NSMakeRange(0, ticketString.length) withTemplate:@":***"];
}

- (void)willSendHTTPRequestToURL:(NSURL *)url withHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers {

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {

    // Obfuscate secrets.
    NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop __unused) {
      if ([key isEqualToString:kMSOneCollectorApiKey]) {
        value = [self obfuscateTargetTokens:value];
      } else if ([key isEqualToString:kMSOneCollectorTicketsKey]) {
        value = [self obfuscateTickets:value];
      }
      [flattenedHeaders addObject:[NSString stringWithFormat:@"%@ = %@", key, value]];
    }];

    // Log URL and headers.
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [flattenedHeaders componentsJoinedByString:@", "]);
  }
}

@end
