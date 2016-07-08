/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVACrashesPrivate.h"
#import "AvalancheHub+Internal.h"

@implementation AVACrashes

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
  AVALogVerbose(@"AVACrashes: Started crash module");
}

- (void)setDelegate:(id<AVAAvalancheDelegate>) delegate {
  _delegate = delegate;
}

+ (void)enable {
  
}

+ (void)disable {
  
}

+ (BOOL)isEnabled {
  return YES;
}

@end
