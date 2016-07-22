/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVACrashesPrivate.h"
#import "AvalancheHub+Internal.h"

@implementation AVACrashes

@synthesize delegate = _delegate;
@synthesize isEnabled = _isEnabled;

+ (id)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
    _isEnabled = YES;
  }
  return self;
}

- (void)startFeature {
  AVALogVerbose(@"AVACrashes: Started crash module");
}

- (void)setDelegate:(id<AVAAvalancheDelegate>) delegate {
  _delegate = delegate;
}

+ (void)setEnable:(BOOL)isEnabled {
  [[self sharedInstance] setEnable:isEnabled];
}

+ (BOOL)isEnabled {
  return [[self sharedInstance] isEnabled];
}
- (void)setEnable:(BOOL)isEnabled {
  _isEnabled = isEnabled;
}

- (BOOL)isEnabled {
  return _isEnabled;
}

@end
