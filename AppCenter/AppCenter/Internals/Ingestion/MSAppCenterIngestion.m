// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterIngestion.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSAppCenterIngestion

static NSString *const kMSAPIVersion = @"1.0.0";
static NSString *const kMSAPIVersionKey = @"api-version";
static NSString *const kMSApiPath = @"/logs";

// URL components' name within a partial URL.
static NSString *const kMSPartialURLComponentsName[] = {@"scheme", @"user", @"password", @"host", @"port", @"path"};

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient baseUrl:(NSString *)baseUrl installId:(NSString *)installId {
  self = [super initWithHttpClient:httpClient
                           baseUrl:baseUrl
                           apiPath:kMSApiPath
                           headers:@{kMSHeaderContentTypeKey : kMSAppCenterContentType, kMSHeaderInstallIDKey : installId}
                      queryStrings:@{kMSAPIVersionKey : kMSAPIVersion}];
  return self;
}

- (BOOL)isReadyToSend {
  return self.appSecret != nil;
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
  if (!self.appSecret) {
    MSLogError([MSAppCenter logTag], @"AppCenter ingestion is used without app secret.");
    return;
  }
  [super sendAsync:data
      completionHandler:^(NSString *_Nonnull __unused callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable responseBody,
                          NSError *_Nullable error) {
        // Ignore the given call ID so that the container's batch ID can be used instead.
        handler(batchId, response, responseBody, error);
      }];
}

- (NSDictionary *)getHeadersWithData:(nullable NSObject *__unused)data eTag:(nullable NSString *__unused)eTag {
  NSMutableDictionary *httpHeaders = [self.httpHeaders mutableCopy];
  [httpHeaders setValue: self.appSecret forKey:kMSHeaderAppSecretKey];
  return httpHeaders;
}

- (NSData *)getPayloadWithData:(nullable NSObject *)data {
  MSLogContainer *container = (MSLogContainer *)data;
  NSString *jsonString = [container serializeLog];
  return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)obfuscateResponsePayload:(NSString *)payload {
  return payload;
}

#pragma mark - MSHttpClientDelegate

- (void)willSendHTTPRequestToURL:(NSURL *)url withHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers {

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {

    // Obfuscate secrets.
    NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop __unused) {
      if ([key isEqualToString:kMSHeaderAppSecretKey]) {
        value = [MSHttpUtil hideSecret:value];
      }
      [flattenedHeaders addObject:[NSString stringWithFormat:@"%@ = %@", key, value]];
    }];

    // Log URL and headers.
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [flattenedHeaders componentsJoinedByString:@", "]);
  }
}

@end
