/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalyticsPrivate.h"
#import "AvalancheHub+Internal.h"
#import "AVAEventLog.h"

@implementation AVAAnalytics

@synthesize delegate = _delegate;

+ (id)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startFeature {  
  AVALogVerbose(@"AVAAnalytics: Started analytics module");
}

- (void)setDelegate:(id<AVAAvalancheDelegate>) delegate {
  _delegate = delegate;
}

+ (void)setEnable:(BOOL)isEnabled {
  
}

+ (BOOL)isEnabled {
  return YES;
}

+ (void)sendEventLog:(NSString*)log {
  [[self sharedInstance] sendEventLog:log];
}

- (void)sendEventLog:(NSString*)name {

  // Send async
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Set log
    AVAEventLog *log = [[AVAEventLog alloc] init];
    log.name = name;
    log.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
    log.eventId = kAVAUUIDString;

    // Send log to core module
    [self.delegate feature:self didCreateLog:log];
  });
}

@end
