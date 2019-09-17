// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSUtility+StringFormatting.h"

static NSTimeInterval kRequestTimeout = 60.0;

// URL components' name within a partial URL.
static NSString *const kMSPartialURLComponentsName[] = {@"scheme", @"user", @"password", @"host", @"port", @"path"};

@implementation MSHttpIngestion

@synthesize baseURL = _baseURL;
@synthesize apiPath = _apiPath;
@synthesize reachability = _reachability;
@synthesize paused = _paused;

#pragma mark - Initialize

- (id)initWithBaseUrl:(NSString *)baseUrl
              apiPath:(NSString *)apiPath
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability {
  return [self initWithBaseUrl:baseUrl
                       apiPath:apiPath
                       headers:headers
                  queryStrings:queryStrings
                  reachability:reachability
                retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]];
}

- (id)initWithBaseUrl:(NSString *)baseUrl
              apiPath:(NSString *)apiPath
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals {
  return [self initWithBaseUrl:baseUrl
                       apiPath:apiPath
                       headers:headers
                  queryStrings:queryStrings
                  reachability:reachability
                retryIntervals:retryIntervals
        maxNumberOfConnections:4];
}

- (id)initWithBaseUrl:(NSString *)baseUrl
                   apiPath:(NSString *)apiPath
                   headers:(NSDictionary *)headers
              queryStrings:(NSDictionary *)queryStrings
              reachability:(MS_Reachability *)reachability
            retryIntervals:(NSArray *)retryIntervals
    maxNumberOfConnections:(NSInteger)maxNumberOfConnections {
  if ((self = [super init])) {
    _httpHeaders = headers;
    _pendingCalls = [NSMutableDictionary new];
    _reachability = reachability;
    _enabled = YES;
    _paused = NO;
    _delegates = [NSHashTable weakObjectsHashTable];
    _callsRetryIntervals = retryIntervals;
    _apiPath = apiPath;
    _maxNumberOfConnections = maxNumberOfConnections;
    _baseURL = baseUrl;

    // Construct the URL string with the query string.
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@%@", baseUrl, apiPath];
    __block NSMutableString *queryStringForEncoding = [NSMutableString new];

    // Set query parameter.
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull queryString, __unused BOOL *_Nonnull stop) {
      [queryStringForEncoding
          appendString:[NSString stringWithFormat:@"%@%@=%@", [queryStringForEncoding length] > 0 ? @"&" : @"", key, queryString]];
    }];
    if ([queryStringForEncoding length] > 0) {
      [urlString appendFormat:@"?%@", [queryStringForEncoding
                                          stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }

    // Set send URL which can't be null
    _sendURL = (NSURL * _Nonnull)[NSURL URLWithString:urlString];

    // Hookup to reachability.
    [MS_NOTIFICATION_CENTER addObserver:self selector:@selector(networkStateChanged:) name:kMSReachabilityChangedNotification object:nil];
    [self.reachability startNotifier];
  }
  return self;
}

#pragma mark - MSIngestion

- (BOOL)isReadyToSend {
  return YES;
}

- (void)sendAsync:(NSObject *)data authToken:(nullable NSString *)authToken completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:nil authToken:authToken callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
    completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:eTag authToken:authToken callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:nil authToken:nil callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data eTag:(nullable NSString *)eTag completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:eTag authToken:nil callId:MS_UUID_STRING completionHandler:handler];
}

- (void)addDelegate:(id<MSIngestionDelegate>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSIngestionDelegate>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

#pragma mark - Life cycle

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  @synchronized(self) {
    if (self.enabled != isEnabled) {
      self.enabled = isEnabled;
      if (isEnabled) {
        [self.reachability startNotifier];
      } else {
        [self.reachability stopNotifier];
        [self pause];

        // Data deletion is required.
        if (deleteData) {

          // Cancel all the tasks and invalidate current session to free resources.
          [self.session invalidateAndCancel];
          self.session = nil;

          // Remove pending calls.
          [self.pendingCalls removeAllObjects];
        }
      }
    }
  }
}

- (void)pause {
  @synchronized(self) {
    if (!self.paused) {
      MSLogInfo([MSAppCenter logTag], @"Pause ingestion.");
      self.paused = YES;

      // Suspend current calls' retry.
      [self.pendingCalls.allValues
          enumerateObjectsUsingBlock:^(MSIngestionCall *_Nonnull call, __unused NSUInteger idx, __unused BOOL *_Nonnull stop) {
            if (!call.submitted) {
              [call resetRetry];
            }
          }];

      // Notify delegates.
      [self enumerateDelegatesForSelector:@selector(ingestionDidPause:)
                                withBlock:^(id<MSIngestionDelegate> delegate) {
                                  [delegate ingestionDidPause:self];
                                }];
    }
  }
}

- (void)resume {
  @synchronized(self) {

    // Resume only while enabled.
    if (self.paused && self.enabled) {
      MSLogInfo([MSAppCenter logTag], @"Resume ingestion.");
      self.paused = NO;

      // Resume calls.
      [self.pendingCalls.allValues
          enumerateObjectsUsingBlock:^(MSIngestionCall *_Nonnull call, __unused NSUInteger idx, __unused BOOL *_Nonnull stop) {
            if (!call.submitted) {
              [self sendCallAsync:call];
            }
          }];

      // Propagate.
      [self enumerateDelegatesForSelector:@selector(ingestionDidResume:)
                                withBlock:^(id<MSIngestionDelegate> delegate) {
                                  [delegate ingestionDidResume:self];
                                }];
    }
  }
}

#pragma mark - MSIngestionCallDelegate

- (void)sendCallAsync:(MSIngestionCall *)call {
  @synchronized(self) {
    if (self.paused || !self.enabled) {
      return;
    }
    if (!call) {
      return;
    }

    // Create the request.
    NSURLRequest *request = [self createRequest:call.data eTag:call.eTag authToken:call.authToken];
    if (!request) {
      return;
    }

    // Create a task for the request.
    NSURLSessionDataTask *task = [self.session
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            @synchronized(self) {
              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
              if (error) {
                MSLogDebug([MSAppCenter logTag], @"HTTP request error with code: %td, domain: %@, description: %@", error.code,
                           error.domain, error.localizedDescription);
              }

              // Don't lose time pretty printing if not going to be printed.
              else if ([MSAppCenter logLevel] <= MSLogLevelVerbose) {
                NSString *contentType = httpResponse.allHeaderFields[kMSHeaderContentTypeKey];
                NSString *payload;

                // Obfuscate payload.
                if (data.length > 0) {
                  if ([contentType hasPrefix:@"application/json"]) {
                    payload = [MSUtility obfuscateString:[MSUtility prettyPrintJson:data]
                                     searchingForPattern:kMSTokenKeyValuePattern
                                   toReplaceWithTemplate:kMSTokenKeyValueObfuscatedTemplate];
                    payload = [MSUtility obfuscateString:payload
                                     searchingForPattern:kMSRedirectUriPattern
                                   toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate];
                  } else if (!contentType.length || [contentType hasPrefix:@"text/"] || [contentType hasPrefix:@"application/"]) {
                    payload = [MSUtility obfuscateString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                     searchingForPattern:kMSTokenKeyValuePattern
                                   toReplaceWithTemplate:kMSTokenKeyValueObfuscatedTemplate];
                    payload = [MSUtility obfuscateString:payload
                                     searchingForPattern:kMSRedirectUriPattern
                                   toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate];
                  } else {
                    payload = @"<binary>";
                  }
                }
                MSLogVerbose([MSAppCenter logTag], @"HTTP response received with status code: %tu, payload:\n%@", httpResponse.statusCode,
                             payload);
              }

              // Call handles the completion.
              if (call) {
                call.submitted = NO;
                [call ingestion:self callCompletedWithResponse:httpResponse data:data error:error];
              }
            }
          }];

    // TODO: Set task priority.
    [task resume];
    call.submitted = YES;
  }
}

- (void)call:(MSIngestionCall *)call completedWithResult:(MSIngestionCallResult)result {
  @synchronized(self) {
    switch (result) {
    case MSIngestionCallResultFatalError: {

      // Disable and delete data.
      [self setEnabled:NO andDeleteDataOnDisabled:YES];

      // Notify delegates.
      [self enumerateDelegatesForSelector:@selector(ingestionDidReceiveFatalError:)
                                withBlock:^(id<MSIngestionDelegate> delegate) {
                                  [delegate ingestionDidReceiveFatalError:self];
                                }];
      break;
    }
    case MSIngestionCallResultRecoverableError:

      // Disable and do not delete data. Do not notify the delegates as this will cause data to be deleted.
      [self setEnabled:NO andDeleteDataOnDisabled:NO];
      break;
    case MSIngestionCallResultSuccess:
      break;
    }

    // Remove call from pending call. This needs to happen after calling setEnabled:andDeleteDataOnDisabled:
    // FIXME: Refactor dependency between calling setEnabled:andDeleteDataOnDisabled: and pause the ingestion.
    NSString *callId = call.callId;
    if (callId.length == 0) {
      MSLogWarning([MSAppCenter logTag], @"Call object is invalid");
      return;
    }
    [self.pendingCalls removeObjectForKey:callId];
    MSLogInfo([MSAppCenter logTag], @"Removed call id:%@ from pending calls:%@", callId, [self.pendingCalls description]);
  }
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)notification {
  (void)notification;
  [self networkStateChanged];
}

#pragma mark - Private

- (void)setBaseURL:(NSString *)baseURL {
  @synchronized(self) {
    BOOL success = false;
    NSURLComponents *components;
    _baseURL = baseURL;
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

- (void)networkStateChanged {
  if ([self.reachability currentReachabilityStatus] == NotReachable) {
    MSLogInfo([MSAppCenter logTag], @"Internet connection is down.");
    [self pause];
  } else {
    MSLogInfo([MSAppCenter logTag], @"Internet connection is up.");
    [self resume];
  }
}

/**
 * This is an empty method expected to be overridden in sub classes.
 */
- (NSURLRequest *)createRequest:(NSObject *)__unused data eTag:(NSString *)__unused eTag authToken:(nullable NSString *)__unused authToken {
  return nil;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  (void)key;
  return value;
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = kRequestTimeout;
    sessionConfiguration.HTTPMaximumConnectionsPerHost = self.maxNumberOfConnections;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    /*
     * Limit callbacks execution concurrency to avoid race condition. This queue
     * is used only for delegate method calls and completion handlers. See
     * https://developer.apple.com/documentation/foundation/nsurlsession/1411571-delegatequeue
     */
    _session.delegateQueue.maxConcurrentOperationCount = 1;
  }
  return _session;
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<MSIngestionDelegate> delegate))block {
  for (id<MSIngestionDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers {
  NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
  for (NSString *headerKey in headers) {
    [flattenedHeaders
        addObject:[NSString stringWithFormat:@"%@ = %@", headerKey, [self obfuscateHeaderValue:headers[headerKey] forKey:headerKey]]];
  }
  return [flattenedHeaders componentsJoinedByString:@", "];
}

- (void)sendAsync:(NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
               callId:(NSString *)callId
    completionHandler:(MSSendAsyncCompletionHandler)handler {
  @synchronized(self) {

    // Check if call has already been created(retry scenario).
    MSIngestionCall *call = self.pendingCalls[callId];
    if (call == nil) {
      call = [[MSIngestionCall alloc] initWithRetryIntervals:self.callsRetryIntervals];
      call.delegate = self;
      call.data = data;
      call.authToken = authToken;
      call.eTag = eTag;
      call.callId = callId;
      call.completionHandler = handler;

      // Store call in calls array.
      self.pendingCalls[callId] = call;
    }
    [self sendCallAsync:call];
  }
}

- (void)dealloc {
  [self.reachability stopNotifier];
  [MS_NOTIFICATION_CENTER removeObserver:self name:kMSReachabilityChangedNotification object:nil];
  [self.session finishTasksAndInvalidate];
}

#pragma mark - Helper

+ (nullable NSString *)eTagFromResponse:(NSHTTPURLResponse *)response {

  // Response header keys are case-insensitive but NSHTTPURLResponse contains case-sensitive keys in Dictionary.
  for (NSString *key in response.allHeaderFields.allKeys) {
    if ([[key lowercaseString] isEqualToString:kMSETagResponseHeader]) {
      return response.allHeaderFields[key];
    }
  }
  return nil;
}

@end
