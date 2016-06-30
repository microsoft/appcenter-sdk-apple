/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
#import "AVAHttpSender.h"
#import "AVALogContainer.h"
#import "AVAAvalanche.h"
#import "AVAAvalanchePrivate.h"

static NSUInteger requestId = 0;
static NSMutableSet * queuedRequests = nil;

// request keys
static NSString* const kApiPath = @"/logs";
static NSString* const kContentTypeJSON = @"application/json";
static NSString* const kAppId = @"App-ID";
static NSString* const kInstallID = @"Install-ID";
static NSString* const kContentType = @"Content-Type";

// API Error
NSString* kAVADefaultApiErrorDomain = @"SWGDefaultApiErrorDomain";
NSInteger kAVADefaultApiMissingParamErrorCode = 234513;

@interface AVAHttpSender ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation AVAHttpSender

-(id)initWithBaseUrl:(NSString*)url {
  if (self = [super init]) {
    queuedRequests = [[NSMutableSet alloc] init];
    _baseURL = url;
  }
  return self;
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  }
  return _session;
}

- (void)sendBatchLog:(AVALogContainer*)logs
               callbackQueue:(dispatch_queue_t)callbackQueue
   completionHandler:(SendAsyncCompletionHandler)handler {
  
  dispatch_async(self.senderBatcheQueue, ^{
    [self sendLogsAsync:logs callbackQueue:callbackQueue completionHandler:handler];
  });
}

-(NSNumber*)sendLogsAsync:(AVALogContainer*)logs
            callbackQueue:(dispatch_queue_t)callbackQueue
        completionHandler:(SendAsyncCompletionHandler)handler {
  
  // Verify parameters
  if (!logs) {
    NSParameterAssert(logs);
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey : @"Missing required parameter 'logs'"};
    NSError* error = [NSError errorWithDomain:kAVADefaultApiErrorDomain code:kAVADefaultApiMissingParamErrorCode userInfo:userInfo];
    AVALogError(@"%@", [error localizedDescription]);
    handler(error);
  }
  
  NSString* appId = [[AVAAvalanche sharedInstance] getAppId];
  NSString* installId = [[AVAAvalanche sharedInstance] getUUID];
  NSString* apiVersion = [[AVAAvalanche sharedInstance] getApiVersion];

  // Create the request
  NSURLRequest* request= [self createRequestWithApiVersion:apiVersion appID:appId installID:installId parameters:logs];

  if (!request)
    return nil;
  
  NSNumber* requestId = [AVAHttpSender queueRequest];
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                            NSInteger statusCode = httpResponse.statusCode;

                                            // Retry
                                            if (statusCode == 408 ||
                                                statusCode == 429 ||
                                                statusCode == 500) {
                                              // TODO retry
                                            }
                                            
                                            // Callback to Channel
                                            else {
                                              dispatch_async(callbackQueue, ^{
                                                // TODO: internal house keeping
                                                handler(error);
                                              });
                                            }
                                          }];
  [task resume];

  // TODO
  return requestId;
}

#pragma mark - URL Session Helper

-(NSURLRequest *)createRequestWithApiVersion:(NSString*)apiVersion
                             appID:(NSString*) appID
                         installID:(NSString*) installID
                        parameters:(AVALogContainer*)parameters {
  
  // Construct the URL string with the query string
  NSString* urlString = [self.baseURL stringByAppendingString:kApiPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
  
  // Set query parameter
  NSURLQueryItem *apiVersionQuery = [NSURLQueryItem queryItemWithName:@"api-version" value:apiVersion];
  components.queryItems = @[ apiVersionQuery ];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
  
  // Set method
  request.HTTPMethod = @"POST";
  
  // Set Headr params
  NSMutableDictionary* headerParams = [NSMutableDictionary dictionary];

  // HTTP header `Accept`
  //headerParams[@"Accept"] = acceptHeader;
  headerParams[kContentType] = kContentTypeJSON;
  headerParams[kAppId] = appID;
  headerParams[kInstallID] = installID;
  request.allHTTPHeaderFields = headerParams;
  
  
  // TODO
  // Set body
  //request.HTTPBody = [AVALogContainerSerializer serialize:parameters];

  // Always disable cookies
  [request setHTTPShouldHandleCookies:NO];

  return request;
}

-(void)handleResponseWithStatusCode:(NSInteger)statusCode responseData:(nonnull NSData *)responseData error:(nonnull NSError *)error {
  NSMutableDictionary* info = [NSMutableDictionary dictionary];

  info[@"error"] = error;
  info[@"statusCode"] = @(statusCode);
  
  if (responseData && (responseData.length > 0)) {
    //we delete data that was either sent successfully or if we have a non-recoverable error
    AVALogDebug(@"INFO: Sent data with status code: %ld", (long) statusCode);
    AVALogDebug(@"INFO: Response data:\n%@", [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil]);
    
    // TODO
    //[self.delegate onResponseReceived:info]
  } else {
    AVALogError(@"ERROR: Sending telemetry data failed");
    AVALogError(@"Error description: %@", error.localizedDescription);
    
    // TODO
    //[self.delegate onResponseReceivedError:info]
  }
}

#pragma mark - Helper

+(NSNumber*)queueRequest {
  NSNumber* requestId = [[self class] nextRequestId];
  AVALogVerbose(@"added %@ to request queue", requestId);
  [queuedRequests addObject:requestId];
  return requestId;
}

+(NSNumber*)nextRequestId {
  @synchronized(self) {
    return @(++requestId);
  }
}

@end
