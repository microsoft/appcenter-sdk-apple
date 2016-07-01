/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAHttpSender.h"
#import "AVALogContainer.h"
#import "AVAAvalanche.h"
#import "AVAAvalanchePrivate.h"
#import "AVAConstants+Internal.h"

static NSUInteger requestId = 0;
static NSMutableSet * queuedRequests = nil;

// Request keys
static NSString* const kApiPath = @"/logs";
static NSString* const kContentTypeJSON = @"application/json";
static NSString* const kAppId = @"App-ID";
static NSString* const kInstallID = @"Install-ID";
static NSString* const kContentType = @"Content-Type";

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

-(NSNumber*)sendLogsAsync:(AVALogContainer*)logs
            callbackQueue:(dispatch_queue_t)callbackQueue
                 priority:(AVASendPriority)priority
        completionHandler:(AVASendAsyncCompletionHandler)handler {
  
  NSString* batchId = @"TODO:logs.batchId";
  
  // Verify parameters
  if (!logs) {
    // TODO Verify assert
    NSParameterAssert(logs);
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey : @"Missing required parameter 'logs'"};
    NSError* error = [NSError errorWithDomain:kAVADefaultApiErrorDomain code:kAVADefaultApiMissingParamErrorCode userInfo:userInfo];
    AVALogError(@"%@", [error localizedDescription]);
    handler(error, kAVADefaultApiMissingParamErrorCode, batchId);

    return nil;
  }
  
  // Create the request
  NSURLRequest* request= [self createRequest:logs];

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
                                                handler(error, statusCode, batchId);
                                              });
                                            }
                                          }];
  [task resume];

  // TODO
  return requestId;
}

#pragma mark - URL Session Helper

- (NSDictionary*)headerParam {
  if (!_headerParam) {

    _headerParam = @{kContentType:kContentTypeJSON,
                     kAppId:[[AVAAvalanche sharedInstance] appId],
                     kInstallID:[[AVAAvalanche sharedInstance] UUID],
                     };
  }
  
  return _headerParam;
}

-(NSURLRequest *)createRequest:(AVALogContainer*)parameters {
  
  // Construct the URL string with the query string
  NSString* urlString = [self.baseURL stringByAppendingString:kApiPath];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
  
  // Set query parameter
  NSURLQueryItem *apiVersionQuery = [NSURLQueryItem queryItemWithName:@"api-version"
                                                                value:[[AVAAvalanche sharedInstance] apiVersion]];
  components.queryItems = @[ apiVersionQuery ];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
  
  // Set method
  request.HTTPMethod = @"POST";
  
  // Set Headr params
  request.allHTTPHeaderFields = [self headerParam];

  // TODO
  // Set body
  //request.HTTPBody = [AVALogContainerSerializer serialize:parameters];

  // Always disable cookies
  [request setHTTPShouldHandleCookies:NO];

  return request;
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
