/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalanche.h"
#import "AVAAvalanchePrivate.h"
#import "AVAConstants+Internal.h"
#import "AVAHttpSender.h"
#import "AVALogContainer.h"

static NSUInteger requestId = 0;
static NSMutableSet *queuedRequests = nil;
static NSTimeInterval kRequestTimeout = 60.0;

// API Path
static NSString *const kAVAApiPath = @"/logs";

@interface AVAHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

@end

@implementation AVAHttpSender

- (id)initWithBaseUrl:(NSString *)baseUrl headers:(NSDictionary *)headers queryStrings:(NSDictionary*)queryStrings {
  if (self = [super init]) {
    
    // Set the request queue
    queuedRequests = [[NSMutableSet alloc] init];
    _httpHeaders = headers;

    // Construct the URL string with the query string
    NSString *urlString = [baseUrl stringByAppendingString:kAVAApiPath];
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray* queryItemArray = [NSMutableArray array];

    // Set query parameter
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      NSURLQueryItem *queryItem = [NSURLQueryItem
                                   queryItemWithName:key
                                   value:obj];
      [queryItemArray addObject:queryItem];
    }];
    components.queryItems = queryItemArray;
    
    // Set send URL
    _sendURL = components.URL;
  }
  return self;
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *sessionConfiguration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = kRequestTimeout;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  }
  return _session;
}

- (NSNumber *)sendAsync:(AVALogContainer *)logs
      completionHandler:(AVASendAsyncCompletionHandler)handler {

  return [self sendAsync:logs
           callbackQueue:dispatch_get_main_queue()
                priority:NSURLSessionTaskPriorityDefault
       completionHandler:handler];
}

- (NSNumber *)sendAsync:(AVALogContainer *)container
          callbackQueue:(dispatch_queue_t)callbackQueue
               priority:(float)priority
      completionHandler:(AVASendAsyncCompletionHandler)handler {

  NSString *batchId = container.batchId;
  
  // Verify container
  if (!container || ![container isValid]) {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey : @"Invalid parameter 'logs'"
                               };
    NSError *error =
    [NSError errorWithDomain:kAVADefaultApiErrorDomain
                        code:kAVADefaultApiMissingParamErrorCode
                    userInfo:userInfo];
    AVALogError(@"%@", [error localizedDescription]);
    handler(error, kAVADefaultApiMissingParamErrorCode, batchId);
    
    return nil;
  }
  
  // Create the request
  NSURLRequest *request = [self createRequest:container];
  
  if (!request)
    return nil;
  
  NSNumber *requestId = [AVAHttpSender queueRequest];
  NSURLSessionDataTask *task = [self.session
                                dataTaskWithRequest:request
                                completionHandler:^(NSData *data, NSURLResponse *response,
                                                    NSError *error) {
                                  // Retry
                                  if ([AVAHttpSender isRecoverableError:response]) {
                                    // TODO retry
                                  }
                                  
                                  // Callback to Channel
                                  else {
                                    dispatch_async(callbackQueue, ^{
                                      // TODO: internal house keeping
                                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                      NSInteger code = httpResponse.statusCode;
                                      
                                      // Completion with error
                                      handler(error, code, batchId);
                                    });
                                  }
                                }];
  // Set task priority
  task.priority = priority;
  [task resume];
  
  // TODO
  return requestId;
}

#pragma mark - URL Session Helper


- (NSURLRequest *)createRequest:(AVALogContainer *)logContainer {
  NSMutableURLRequest *request =
      [NSMutableURLRequest requestWithURL:_sendURL];

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

+ (BOOL)isRecoverableError:(NSURLResponse *)response {
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  NSInteger code = httpResponse.statusCode;

  return code >= 500 || code == 408 || code == 429;
}

#pragma mark - Helper

+ (NSNumber *)queueRequest {
  NSNumber *requestId = [[self class] nextRequestId];
  AVALogVerbose(@"added %@ to request queue", requestId);
  [queuedRequests addObject:requestId];
  return requestId;
}

+ (NSNumber *)nextRequestId {
  @synchronized(self) {
    return @(++requestId);
  }
}

@end
