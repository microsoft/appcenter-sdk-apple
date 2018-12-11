#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSIngestionCall.h"

@implementation MSIngestionCall

@synthesize completionHandler = _completionHandler;
@synthesize data = _data;
@synthesize callId = _callId;
@synthesize submitted = _submitted;
@synthesize delegate = _delegate;

- (id)initWithRetryIntervals:(NSArray *)retryIntervals {
  if ((self = [super init])) {
    _retryIntervals = retryIntervals;
    _submitted = NO;
  }
  return self;
}

- (BOOL)hasReachedMaxRetries {
  return self.retryCount >= self.retryIntervals.count;
}

- (uint32_t)delayForRetryCount:(NSUInteger)retryCount {
  if (retryCount >= self.retryIntervals.count) {
    return 0;
  }

  // Create a random delay.
  uint32_t delay = [(NSNumber *)self.retryIntervals[retryCount] unsignedIntValue] / 2;
  delay += arc4random_uniform(delay);

  return delay;
}

- (void)startRetryTimerWithStatusCode:(NSUInteger)statusCode {
  [self resetTimer];

  // Create queue.
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
  int64_t delta = NSEC_PER_SEC * [self delayForRetryCount:self.retryCount];
  MSLogWarning([MSAppCenter logTag], @"Call attempt #%tu failed with status code: %tu, it will be retried in %.f ms.", self.retryCount,
               statusCode, round(delta / 1000000));
  self.retryCount++;
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, delta), 1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.timerSource, ^{
    typeof(self) strongSelf = weakSelf;

    // Do send.
    if (strongSelf) {
      [self.delegate sendCallAsync:self];
      [strongSelf resetTimer];
    }
  });
  dispatch_resume(self.timerSource);
}

- (void)resetTimer {
  if (self.timerSource) {
    dispatch_source_cancel(self.timerSource);
  }
}

- (void)resetRetry {
  self.retryCount = 0;
  [self resetTimer];
}

- (void)ingestion:(id<MSIngestionProtocol>)ingestion
    callCompletedWithStatus:(NSUInteger)statusCode
                       data:(nullable NSData *)data
                      error:(NSError *)error {
  BOOL internetIsDown = [MSIngestionUtil isNoInternetConnectionError:error];
  BOOL couldNotEstablishSecureConnection = [MSIngestionUtil isSSLConnectionError:error];

  if (internetIsDown || couldNotEstablishSecureConnection) {

    // Reset the retry count, will retry once the (secure) connection is established again.
    [self resetRetry];
    NSString *logMessage = internetIsDown ? @"Internet connection is down." : @"Could not establish secure connection.";
    MSLogInfo([MSAppCenter logTag], @"Ingestion call failed with error: %@", logMessage);
  }

  // Retry.
  else if ([MSIngestionUtil isRecoverableError:statusCode] && ![self hasReachedMaxRetries]) {
    [self startRetryTimerWithStatusCode:statusCode];
  }

  // Call was a) successful, b) we exhausted retries for a recoverable error or c) have an unrecoverable error.
  else {

    // Wrap the status code in an error whenever the call failed.
    // TODO: Handle 2xx codes.
    if (!error && statusCode != MSHTTPCodesNo200OK) {
      NSDictionary *userInfo =
          @{ NSLocalizedDescriptionKey : kMSACConnectionHttpErrorDesc,
             kMSACConnectionHttpCodeErrorKey : @(statusCode) };
      error = [NSError errorWithDomain:kMSACErrorDomain code:kMSACConnectionHttpErrorCode userInfo:userInfo];
    }

    // Check for error.
    BOOL recoverableError = ([MSIngestionUtil isRecoverableError:statusCode] && [self hasReachedMaxRetries]);
    BOOL fatalError;
    fatalError = recoverableError ? NO : (error && error.code != NSURLErrorCancelled);

    // Call completion handler.
    if (self.completionHandler) {
      self.completionHandler(self.callId, statusCode, data, error);
    }

    // Handle recoverable error.
    if (recoverableError) {
      [ingestion call:self completedWithResult:MSIngestionCallResultRecoverableError];
    }

    // Handle fatal error.
    else if (fatalError) {
      [ingestion call:self completedWithResult:MSIngestionCallResultFatalError];
    }

    // Handle success case.
    else {
      [ingestion call:self completedWithResult:MSIngestionCallResultSuccess];
    }
  }
}

@end
