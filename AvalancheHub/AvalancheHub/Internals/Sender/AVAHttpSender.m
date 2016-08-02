/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalanchePrivate.h"
#import "AVAHttpSender.h"
#import "AVARetriableCall.h"
#import "AVASenderUtils.h"
#import "AVAUtils.h"

static NSTimeInterval kRequestTimeout = 60.0;

// API Path
static NSString *const kAVAApiPath = @"/logs";

@interface AVAHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

@end

@implementation AVAHttpSender

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(AVA_Reachability *)reachability {
  if (self = [super init]) {
    _httpHeaders = headers;
    _pendingCalls = [NSMutableDictionary new];
    _reachability = reachability;

    // Construct the URL string with the query string
    NSString *urlString = [baseUrl stringByAppendingString:kAVAApiPath];
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray *queryItemArray = [NSMutableArray array];

    // Set query parameter
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
      NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:obj];
      [queryItemArray addObject:queryItem];
    }];
    components.queryItems = queryItemArray;

    // Set send URL
    _sendURL = components.URL;

    [kAVANotificationCenter addObserver:self
                               selector:@selector(networkStateChanged:)
                                   name:kAVAReachabilityChangedNotification
                                 object:nil];
    [self.reachability startNotifier];
  }
  return self;
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = kRequestTimeout;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  }
  return _session;
}

- (void)sendCallAsync:(id<AVASenderCall>)call {
  if (!call)
    return;

  // Create the request
  NSURLRequest *request = [self createRequest:call.logContainer];

  if (!request)
    return;

  call.isProcessing = YES;

  NSURLSessionDataTask *task = [self.session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

          NSInteger statusCode = [AVASenderUtils getStatusCode:response];
          AVALogVerbose(@"INFO:HTTP response received with the status code:%lu", (unsigned long)statusCode);

          // Call handles the completion
          if (call)
            [call sender:self callCompletedWithError:error status:statusCode];
        }];

  // TODO: Set task priority
  [task resume];
}

- (void)sendAsync:(AVALogContainer *)container
    callbackQueue:(dispatch_queue_t)callbackQueue
completionHandler:(AVASendAsyncCompletionHandler)handler {
  NSString *batchId = container.batchId;
  AVALogVerbose(@"[Sender] INFO: Sending log for batch ID %@", batchId);

  // Verify container
  if (!container || ![container isValid]) {

    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Invalid parameter'" };
    NSError *error =
        [NSError errorWithDomain:kAVADefaultApiErrorDomain code:kAVADefaultApiMissingParamErrorCode userInfo:userInfo];
    AVALogError(@"[Sender] ERROR: %@", [error localizedDescription]);
    handler(batchId, error, kAVADefaultApiMissingParamErrorCode);
    return;
  }

  // Set a default queue
  if (!callbackQueue)
    callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  // Check if call has already been created(retry scenario)
  id<AVASenderCall> call = self.pendingCalls[batchId];
  if (call == nil) {
    call = [[AVARetriableCall alloc] initWithSender:self];
    call.logContainer = container;
    call.callbackQueue = callbackQueue;
    call.completionHandler = handler;

    // Store call in calls array
    self.pendingCalls[batchId] = call;
  }
  [self sendCallAsync:call];
}

- (void)callCompletedWithId:(NSString *)callId {
  if (!callId) {
    AVALogWarning(@"[Sender] WARNING: call object is invalid");
    return;
  }

  [self.pendingCalls removeObjectForKey:callId];
  AVALogVerbose(@"[Sender] INFO: Removed batch id:%@ from pendingCalls:%@", callId, [self.pendingCalls description]);
}

- (void)networkStateChanged:(NSNotificationCenter *)notification {
  // Retrieve current network status
  NetworkStatus newConnectionStatus = [self.reachability currentReachabilityStatus];

  if (newConnectionStatus == NotReachable) {

    // Cancel all the tasks
    [self.session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> *_Nonnull tasks) {
      [tasks
          enumerateObjectsUsingBlock:^(__kindof NSURLSessionTask *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [obj cancel];
          }];

      // Set pending calls to not processing
      [self.pendingCalls.allValues
          enumerateObjectsUsingBlock:^(id<AVASenderCall> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            obj.isProcessing = NO;
          }];
    }];
  } else {

    // Send all pending calls if not already being processed
    [self.pendingCalls.allValues
        enumerateObjectsUsingBlock:^(id<AVASenderCall> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          if (!obj.isProcessing)
            [self sendCallAsync:obj];
        }];
  }
}

#pragma mark - URL Session Helper

- (NSURLRequest *)createRequest:(AVALogContainer *)logContainer {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_sendURL];

  // Set method
  request.HTTPMethod = @"POST";

  // Set Header params
  request.allHTTPHeaderFields = _httpHeaders;

  // Set body
  NSString *jsonString = [logContainer serializeLog];
  request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // Always disable cookies
  [request setHTTPShouldHandleCookies:NO];

  return request;
}

@end
