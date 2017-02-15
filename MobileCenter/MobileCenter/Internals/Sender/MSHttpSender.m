#import "MSHttpSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSMobileCenterInternal.h"
#import "MSSenderCall.h"

static NSTimeInterval kRequestTimeout = 60.0;

@implementation MSHttpSender

@synthesize reachability = _reachability;
@synthesize suspended = _suspended;

#pragma mark - MSSender

- (id)initWithBaseUrl:(NSString *)baseUrl
              apiPath:(NSString *)apiPath
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals {
  if (self = [super init]) {
    _httpHeaders = headers;
    _pendingCalls = [NSMutableDictionary new];
    _reachability = reachability;
    _enabled = YES;
    _suspended = NO;
    _delegates = [NSHashTable weakObjectsHashTable];
    _callsRetryIntervals = retryIntervals;

    // Construct the URL string with the query string.
    NSString *urlString = [baseUrl stringByAppendingString:apiPath];
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray *queryItemArray = [NSMutableArray array];

    // Set query parameter.
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull queryString, BOOL *_Nonnull stop) {
      NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:key value:queryString];
      [queryItemArray addObject:queryItem];
    }];
    components.queryItems = queryItemArray;

    // Set send URL.
    _sendURL = components.URL;

    // Hookup to reachability.
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(networkStateChanged:)
                                   name:kMSReachabilityChangedNotification
                                 object:nil];
    [self.reachability startNotifier];

    // Apply current network state.
    [self networkStateChanged];
  }
  return self;
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data callId:MS_UUID_STRING completionHandler:handler];
}

- (void)addDelegate:(id<MSSenderDelegate>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSSenderDelegate>)delegate {
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
        [self resume];
        [self.reachability startNotifier];
      } else {
        [self.reachability stopNotifier];
        [self suspend];

        // Data deletion is required.
        if (deleteData) {

          // Cancel all the tasks and invalidate current session to free resources.
          [self.session invalidateAndCancel];
          self.session = nil;

          // Remove pending calls.
          [self.pendingCalls removeAllObjects];
        }
      }

      // Forward enabled state.
      [self
          enumerateDelegatesForSelector:@selector(senderDidSuspend:)
                              withBlock:^(id<MSSenderDelegate> delegate) {
                                [delegate sender:self didSetEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:deleteData];
                              }];
    }
  }
}

- (void)suspend {
  @synchronized(self) {
    if (!self.suspended) {
      MSLogInfo([MSMobileCenter logTag], @"Suspend sender.");
      self.suspended = YES;

      // Suspend all tasks.
      [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                                    NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                                    NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks) {
        [dataTasks enumerateObjectsUsingBlock:^(__kindof NSURLSessionTask *_Nonnull call, NSUInteger idx,
                                                BOOL *_Nonnull stop) {
          [call suspend];
        }];
      }];

      // Suspend current calls' retry.
      [self.pendingCalls.allValues
          enumerateObjectsUsingBlock:^(MSSenderCall *_Nonnull call, NSUInteger idx, BOOL *_Nonnull stop) {
            if (!call.submitted) {
              [call resetRetry];
            }
          }];

      // Notify delegates.
      [self enumerateDelegatesForSelector:@selector(senderDidSuspend:)
                                withBlock:^(id<MSSenderDelegate> delegate) {
                                  [delegate senderDidSuspend:self];
                                }];
    }
  }
}

- (void)resume {
  @synchronized(self) {

    // Resume only while enabled.
    if (self.suspended && self.enabled) {
      MSLogInfo([MSMobileCenter logTag], @"Resume sender.");
      self.suspended = NO;

      // Resume existing calls.
      [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                                    NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                                    NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks) {
        [dataTasks enumerateObjectsUsingBlock:^(__kindof NSURLSessionTask *_Nonnull call, NSUInteger idx,
                                                BOOL *_Nonnull stop) {
          [call resume];
        }];
      }];

      // Resume calls.
      [self.pendingCalls.allValues
          enumerateObjectsUsingBlock:^(MSSenderCall *_Nonnull call, NSUInteger idx, BOOL *_Nonnull stop) {
            if (!call.submitted) {
              [self sendCallAsync:call];
            }
          }];

      // Propagate.
      [self enumerateDelegatesForSelector:@selector(senderDidResume:)
                                withBlock:^(id<MSSenderDelegate> delegate) {
                                  [delegate senderDidResume:self];
                                }];
    }
  }
}

#pragma mark - MSSenderCallDelegate

- (void)sendCallAsync:(MSSenderCall *)call {
  @synchronized(self) {
    if (self.suspended)
      return;

    if (!call)
      return;

    // Create the request.
    NSURLRequest *request = [self createRequest:call.data];
    if (!request)
      return;

    // Create a task for the request.
    NSURLSessionDataTask *task =
        [self.session dataTaskWithRequest:request
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          @synchronized(self) {
                            NSInteger statusCode = [MSSenderUtil getStatusCode:response];
                            MSLogDebug([MSMobileCenter logTag], @"HTTP response received with status code:%lu",
                                       (unsigned long)statusCode);

                            // Call handles the completion.
                            if (call) {
                              call.submitted = NO;
                              [call sender:self callCompletedWithStatus:statusCode error:error];
                            }
                          }
                        }];

    // TODO: Set task priority.
    [task resume];
    call.submitted = YES;
  }
}

- (void)callCompletedWithId:(NSString *)callId {
  @synchronized(self) {
    if (!callId) {
      MSLogWarning([MSMobileCenter logTag], @"Call object is invalid");
      return;
    }
    [self.pendingCalls removeObjectForKey:callId];
    MSLogInfo([MSMobileCenter logTag], @"Removed batch id:%@ from pending calls:%@", callId,
              [self.pendingCalls description]);
  }
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)notification {
  [self networkStateChanged];
}

#pragma mark - Private

- (void)networkStateChanged {
  if ([self.reachability currentReachabilityStatus] == NotReachable) {
    MSLogInfo([MSMobileCenter logTag], @"Internet connection is down.");
    [self suspend];
  } else {
    MSLogInfo([MSMobileCenter logTag], @"Internet connection is up.");
    [self resume];
  }
}

/**
 * This is an empty method and expect to be overridden in sub classes.
 */
- (NSURLRequest *)createRequest:(NSObject *)data {
  return nil;
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

- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers {
  NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
  for (NSString *headerKey in headers) {
    NSString *header =
        [headerKey isEqualToString:kMSHeaderAppSecretKey] ? [self hideSecret:headers[headerKey]] : headers[headerKey];
    [flattenedHeaders addObject:[NSString stringWithFormat:@"%@ = %@", headerKey, header]];
  }
  return [flattenedHeaders componentsJoinedByString:@", "];
}

- (void)sendAsync:(NSObject *)data callId:(NSString *)callId completionHandler:(MSSendAsyncCompletionHandler)handler {
  @synchronized(self) {

    // Check if call has already been created(retry scenario).
    MSSenderCall *call = self.pendingCalls[callId];
    if (call == nil) {
      call = [[MSSenderCall alloc] initWithRetryIntervals:_callsRetryIntervals];
      call.delegate = self;
      call.data = data;
      call.callId = callId;
      call.completionHandler = handler;

      // Store call in calls array.
      self.pendingCalls[callId] = call;
    }
    [self sendCallAsync:call];
  }
}

- (NSString *)hideSecret:(NSString *)secret {

  // Hide everything if secret is shorter than the max number of displayed characters.
  NSUInteger appSecretHiddenPartLength =
      (secret.length > kMSMaxCharactersDisplayedForAppSecret ? secret.length - kMSMaxCharactersDisplayedForAppSecret
                                                             : secret.length);
  NSString *appSecretHiddenPart =
      [@"" stringByPaddingToLength:appSecretHiddenPartLength withString:kMSHidingStringForAppSecret startingAtIndex:0];
  return [secret stringByReplacingCharactersInRange:NSMakeRange(0, appSecretHiddenPart.length)
                                         withString:appSecretHiddenPart];
}

@end
