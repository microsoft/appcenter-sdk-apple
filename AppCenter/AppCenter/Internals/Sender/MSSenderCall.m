#import "MSAppCenterErrors.h"
#import "MSAppCenterInternal.h"
#import "MSSenderCall.h"

@implementation MSSenderCall

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
  if (retryCount >= self.retryIntervals.count)
    return 0;

  // Create a random delay.
  uint32_t delay = [self.retryIntervals[retryCount] unsignedIntValue] / 2;
  delay += arc4random_uniform(delay);

  return delay;
}

- (void)startTimer {
  [self resetTimer];

  // Create queue.
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
  int64_t delta = NSEC_PER_SEC * [self delayForRetryCount:self.retryCount];
  MSLogDebug([MSAppCenter logTag], @"Call attempt #%lu failed, it will be retried in %.f ms.",
             (unsigned long)self.retryCount, round(delta / 1000000));
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

- (void)sender:(id<MSSender>)sender
    callCompletedWithStatus:(NSUInteger)statusCode
                       data:(NSData *)data
                      error:(NSError *)error {
  BOOL internetIsDown = [MSSenderUtil isNoInternetConnectionError:error];
  BOOL couldNotEstablishSecureConnection = [MSSenderUtil isSSLConnectionError:error];
  if (internetIsDown || couldNotEstablishSecureConnection) {

    // Reset the retry count, will retry once the (secure) connection is established again.
    [self resetRetry];
    NSString *logMessage = internetIsDown ? @"Internet connection is down." : @"Could not establish secure connection.";
    MSLogInfo([MSAppCenter logTag], logMessage);
    [sender suspend];
  }

  // Retry.
  else if ([MSSenderUtil isRecoverableError:statusCode] && ![self hasReachedMaxRetries]) {
    [self startTimer];
  }

  // Callback to Channel.
  else {
    BOOL fatalError;

    // Wrap the status code in an error whenever the call failed.
    if (!error && statusCode != MSHTTPCodesNo200OK) {
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : kMSMCConnectionHttpErrorDesc,
        kMSMCConnectionHttpCodeErrorKey : @(statusCode)
      };
      error = [NSError errorWithDomain:kMSMCErrorDomain code:kMSMCConnectionHttpErrorCode userInfo:userInfo];
    }

    // Detect fatal error.
    fatalError = (error && error.code != NSURLErrorCancelled);

    // Call completion.
    self.completionHandler(self.callId, statusCode, data, error);

    // Remove call from sender.
    [sender call:self completedWithFatalError:fatalError];
  }
}

@end
