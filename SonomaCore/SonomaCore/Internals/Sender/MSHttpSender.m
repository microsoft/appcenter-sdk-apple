/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSHttpSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSRetriableCall.h"
#import "MSSenderDelegate.h"
#import "MSMobileCenterInternal.h"

static NSTimeInterval kRequestTimeout = 60.0;

// API Path.
static NSString *const kMSApiPath = @"/logs";

@implementation MSHttpSender

@synthesize reachability = _reachability;
@synthesize suspended = _suspended;

#pragma mark - MSMSender

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability {
  if (self = [super init]) {
    _httpHeaders = headers;
    _pendingCalls = [NSMutableDictionary new];
    _reachability = reachability;
    _enabled = YES;
    _suspended = NO;
    _delegates = [NSHashTable weakObjectsHashTable];

    // Call's retry intervals are: 10 sec, 5 min, 20 min.
    _callsRetryIntervals = @[ @(10), @(5 * 60), @(20 * 60) ];

    // Construct the URL string with the query string.
    NSString *urlString = [baseUrl stringByAppendingString:kMSApiPath];
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray *queryItemArray = [NSMutableArray array];

    // Set query parameter.
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
      NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:obj];
      [queryItemArray addObject:queryItem];
    }];
    components.queryItems = queryItemArray;

    // Set send URL.
    _sendURL = components.URL;

    // Hookup to reachability.
    [kMSNotificationCenter addObserver:self
                               selector:@selector(networkStateChanged:)
                                   name:kMSReachabilityChangedNotification
                                 object:nil];
    [self.reachability startNotifier];

    // Apply current network state.
    [self networkStateChanged];
  }
  return self;
}

- (void)sendAsync:(MSLogContainer *)container completionHandler:(MSSendAsyncCompletionHandler)handler {
  NSString *batchId = container.batchId;

  // Verify container.
  if (!container || ![container isValid]) {

    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Invalid parameter'" };
    NSError *error =
        [NSError errorWithDomain:kMSDefaultApiErrorDomain code:kMSDefaultApiMissingParamErrorCode userInfo:userInfo];
    MSLogError([MSMobileCenter getLoggerTag], @"%@", [error localizedDescription]);
    handler(batchId, error, kMSDefaultApiMissingParamErrorCode);
    return;
  }

  // Check if call has already been created(retry scenario).
  id<MSSenderCall> call = self.pendingCalls[batchId];
  if (call == nil) {
    call = [[MSRetriableCall alloc] initWithRetryIntervals:self.callsRetryIntervals];
    call.delegate = self;
    call.logContainer = container;
    call.completionHandler = handler;

    // Store call in calls array.
    self.pendingCalls[batchId] = call;
  }
  [self sendCallAsync:call];
}

- (void)addDelegate:(id<MSSenderDelegate>)delegate {
  [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<MSSenderDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - Life cycle

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData {
  if (self.enabled != isEnabled) {
    self.enabled = isEnabled;
    if (isEnabled) {
      [self resume];
      [self.reachability startNotifier];
    } else {
      [self.reachability stopNotifier];
      [self suspend];

      // Delete calls if requested.
      if (deleteData) {
        [self.pendingCalls removeAllObjects];
      }
    }

    // Forward enabled state.
    [self enumerateDelegatesForSelector:@selector(senderDidSuspend:)
                              withBlock:^(id<MSSenderDelegate> delegate) {
                                [delegate sender:self
                                         didSetEnabled:(BOOL)isEnabled
                                    andDeleteDataOnDisabled:deleteData];
                              }];
  }
}

- (void)suspend {
  if (!self.suspended) {
    MSLogInfo([MSMobileCenter getLoggerTag], @"Suspend sender.");
    self.suspended = YES;

    // Set pending calls to not processing.
    [self.pendingCalls.allValues
        enumerateObjectsUsingBlock:^(id<MSSenderCall> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          obj.isProcessing = NO;
        }];

    // Cancel all the tasks.
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                                  NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                                  NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks) {
      [dataTasks
          enumerateObjectsUsingBlock:^(__kindof NSURLSessionTask *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [obj cancel];
          }];
    }];
    [self enumerateDelegatesForSelector:@selector(senderDidSuspend:)
                              withBlock:^(id<MSSenderDelegate> delegate) {
                                [delegate senderDidSuspend:self];
                              }];
  }
}

- (void)resume {

  // Resume only while enabled.
  if (self.suspended && self.enabled) {
    MSLogInfo([MSMobileCenter getLoggerTag], @"Resume sender.");
    self.suspended = NO;

    // Send all pending calls.
    [self.pendingCalls.allValues
        enumerateObjectsUsingBlock:^(id<MSSenderCall> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          if (!obj.isProcessing) {
            [self sendCallAsync:obj];
          }
        }];

    // Propagate.
    [self enumerateDelegatesForSelector:@selector(senderDidResume:)
                              withBlock:^(id<MSSenderDelegate> delegate) {
                                [delegate senderDidResume:self];
                              }];
  }
}

#pragma mark - MSSenderCallDelegate

- (void)sendCallAsync:(id<MSSenderCall>)call {
  if (!call)
    return;

  // Create the request.
  NSURLRequest *request = [self createRequest:call.logContainer];

  if (!request)
    return;

  call.isProcessing = YES;

  NSURLSessionDataTask *task =
      [self.session dataTaskWithRequest:request
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        NSInteger statusCode = [MSSenderUtils getStatusCode:response];
                        MSLogDebug([MSMobileCenter getLoggerTag], @"HTTP response received with status code:%lu",
                                    (unsigned long)statusCode);

                        // Call handles the completion.
                        if (call)
                          [call sender:self callCompletedWithStatus:statusCode error:error];
                      }];

  // TODO: Set task priority.
  [task resume];
}

- (void)callCompletedWithId:(NSString *)callId {
  if (!callId) {
    MSLogWarning([MSMobileCenter getLoggerTag], @"Call object is invalid");
    return;
  }

  [self.pendingCalls removeObjectForKey:callId];
  MSLogInfo([MSMobileCenter getLoggerTag], @"Removed batch id:%@ from pending calls:%@", callId,
             [self.pendingCalls description]);
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)notification {
  [self networkStateChanged];
}

#pragma mark - URL Session Helper

- (NSURLRequest *)createRequest:(MSLogContainer *)logContainer {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_sendURL];

  // Set method.
  request.HTTPMethod = @"POST";

  // Set Header params.
  request.allHTTPHeaderFields = _httpHeaders;

  // Set body.
  NSString *jsonString = [logContainer serializeLog];
  request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  return request;
}

#pragma mark - Private

- (void)networkStateChanged {
  if ([self.reachability currentReachabilityStatus] == NotReachable) {
    MSLogInfo([MSMobileCenter getLoggerTag], @"Internet connection is down.");
    [self suspend];
  } else {
    MSLogInfo([MSMobileCenter getLoggerTag], @"Internet connection is up.");
    [self resume];
  }
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = kRequestTimeout;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  }
  return _session;
}

- (void)enumerateDelegatesForSelector:(SEL)selector withBlock:(void (^)(id<MSSenderDelegate> delegate))block {
  for (id<MSSenderDelegate> delegate in self.delegates) {
    if (delegate && [delegate respondsToSelector:selector]) {
      block(delegate);
    }
  }
}

@end
