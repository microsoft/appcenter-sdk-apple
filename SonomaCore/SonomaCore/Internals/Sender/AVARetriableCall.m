/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVARetriableCall.h"

static NSUInteger kAVAMaxRetryCount = 3;

@interface AVARetriableCall ()

@property(nonatomic) NSArray *retryIntervals;

@end

@implementation AVARetriableCall

@synthesize completionHandler = _completionHandler;
@synthesize isProcessing = _isProcessing;
@synthesize callbackQueue = _callbackQueue;
@synthesize logContainer = _logContainer;
@synthesize delegate = _delegate;

- (id)init {
  if (self = [super init]) {
    // Intervals are: 10 sec, 5 min, 20 min.
    _retryIntervals = @[ @(10), @(5 * 60), @(20 * 60) ];
  }
  return self;
}

- (BOOL)hasReachedMaxRetries {
  return self.retryCount >= kAVAMaxRetryCount;
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
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  self.retryCount++;
  int64_t delta = NSEC_PER_SEC * [self delayForRetryCount:self.retryCount];
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, delta), 1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.timerSource, ^{
    typeof(self) strongSelf = weakSelf;

    // Do send.
    [self.delegate sendCallAsync:self];
    [strongSelf resetTimer];
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

- (void)sender:(id<AVASenderCallDelegate>)sender callCompletedWithError:(NSError *)error status:(NSUInteger)statusCode {
  if ([AVASenderUtils isNoInternetConnectionError:error] || [AVASenderUtils isRequestCanceledError:error]) {

    // Reset the retry count, will retry once the connection is established again.
    [self resetRetry];
    _isProcessing = NO;
  }

  // Retry.
  else if ([AVASenderUtils isRecoverableError:statusCode] && ![self hasReachedMaxRetries]) {
    [self startTimer];
  }

  // Callback to Channel.
  else {

    // Remove call from sender.
    [sender callCompletedWithId:self.logContainer.batchId];

    // Call completion async.
    dispatch_async(self.callbackQueue, ^{
      self.completionHandler(self.logContainer.batchId, error, statusCode);
    });
  }
}

@end
