/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalytics.h"
#import "AvalancheHub+Internal.h"

@implementation AVAAnalytics

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

@end
