/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSRetriableCall.h"
#import "MSRetriableCallPrivate.h"
#import "MSMobileCenterInternal.h"

@implementation MSRetriableCall

@synthesize completionHandler = _completionHandler;
@synthesize isProcessing = _isProcessing;
@synthesize logContainer = _logContainer;
@synthesize delegate = _delegate;

- (id)initWithRetryIntervals:(NSArray *)retryIntervals {
  if (self = [super init]) {
    _retryIntervals = retryIntervals;
  }
  return self;
}

- (BOOL)hasReachedMaxRetries {
  return self.retryCount >= self.retryIntervals.count;
}

- (NSTimeInterval)delayForRetryCount:(NSUInteger)retryCount {
  if (retryCount >= self.retryIntervals.count)
    return 0;

  // Create a random delay.
  NSTimeInterval delay = [self.retryIntervals[retryCount] doubleValue] / 2;
  delay += arc4random_uniform(delay);

  return delay;
}

- (void)startTimer {
  [self resetTimer];

  // Create queue.
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
  int64_t delta = NSEC_PER_SEC * [self delayForRetryCount:self.retryCount];
  MSLogDebug([MSMobileCenter getLoggerTag], @"Call attempt #%lu failed, it will be retried in %.f ms.", (unsigned long)self.retryCount,
              round(delta / 1000000));
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
    self.timerSource = nil;
  }
}

- (void)resetRetry {
  _retryCount = 0;
  [self resetTimer];
}

- (void)sender:(id<MSSender>)sender callCompletedWithStatus:(NSUInteger)statusCode error:(NSError *)error {
  if ([MSSenderUtil isNoInternetConnectionError:error]) {

    // Reset the retry count, will retry once the connection is established again.
    [self resetRetry];
    _isProcessing = NO;
    MSLogInfo([MSMobileCenter getLoggerTag], @"Internet connection is down.");
    [sender suspend];
  }

  // Retry.
  else if ([MSSenderUtil isRecoverableError:statusCode] && ![self hasReachedMaxRetries]) {
    [self startTimer];
  }

  // Callback to Channel.
  else {

    // Call completion.
    self.completionHandler(self.logContainer.batchId, error, statusCode);

    // Remove call from sender.
    [sender callCompletedWithId:self.logContainer.batchId];
  }
}

@end
