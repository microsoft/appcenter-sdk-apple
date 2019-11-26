// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterIngestion.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSCompression.h"
#import "MSConstants+Internal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLogContainer.h"
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

- (void)sendAsync:(NSObject *)data authToken:(NSString *)authToken completionHandler:(MSSendAsyncCompletionHandler)handler {
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
    //TODO handler
    return;
  }

  [super sendAsync:data authToken:authToken completionHandler:handler];
}

- (NSDictionary *)getHeadersWithData:(nullable NSObject * __unused)data eTag:(nullable NSString * __unused)eTag authToken:(nullable NSString *)authToken {
  NSMutableDictionary *httpHeaders = [self.httpHeaders mutableCopy];
  [httpHeaders setValue:self.appSecret forKey:kMSHeaderAppSecretKey];
  if ([authToken length] > 0) {
    NSString *bearerTokenHeader = [NSString stringWithFormat:kMSBearerTokenHeaderFormat, authToken];
    [httpHeaders setValue:bearerTokenHeader forKey:kMSAuthorizationHeaderKey];
  }
  return httpHeaders;
}

- (NSData *)getPayloadWithData:(nullable NSObject *)data {
  MSLogContainer *container = (MSLogContainer *)data;
  NSString *jsonString = [container serializeLog];
  return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)setBaseURL:(NSString *)baseURL {
  @synchronized(self) {
    BOOL success = false;
    NSURLComponents *components;
    self.baseURL = baseURL;
    NSURL *partialURL = [NSURL URLWithString:[baseURL stringByAppendingString:self.apiPath]];

    // Merge new parial URL and current full URL.
    if (partialURL) {
      components = [NSURLComponents componentsWithURL:self.sendURL resolvingAgainstBaseURL:NO];
      @try {
        for (u_long i = 0; i < sizeof(kMSPartialURLComponentsName) / sizeof(*kMSPartialURLComponentsName); i++) {
          NSString *propertyName = kMSPartialURLComponentsName[i];
          [components setValue:[partialURL valueForKey:propertyName] forKey:propertyName];
        }
      } @catch (NSException *ex) {
        MSLogInfo([MSAppCenter logTag], @"Error while updating HTTP URL %@ with %@: \n%@", self.sendURL.absoluteString, baseURL, ex);
      }

      // Update full URL.
      if (components.URL) {
        self.sendURL = (NSURL * _Nonnull) components.URL;
        success = true;
      }
    }

    // Notify failure.
    if (!success) {
      MSLogInfo([MSAppCenter logTag], @"Failed to update HTTP URL %@ with %@", self.sendURL.absoluteString, baseURL);
    }
  }
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  if ([key isEqualToString:kMSAuthorizationHeaderKey]) {
    return [MSHttpUtil hideAuthToken:value];
  } else if ([key isEqualToString:kMSHeaderAppSecretKey]) {
    return [MSHttpUtil hideSecret:value];
  }
  return value;
}

@end
