/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalancheInternal.h"
#import "AVAFeatureAbstract.h"
#import "AVAFeatureAbstractInternal.h"
#import "AVAFeatureAbstractPrivate.h"
#import "AVAUserDefaults.h"
#import "AVAUtils.h"
#import "SonomaCore+Internal.h"

@implementation AVAFeatureAbstract

@synthesize logManger = _logManager;
@synthesize delegate = _delegate;

- (instancetype)init {
  return [self initWithStorage:kAVAUserDefaults];
}

- (instancetype)initWithStorage:(AVAUserDefaults *)storage {
  if (self = [super init]) {

    _isEnabledKey = [NSString stringWithFormat:@"kAVA%@IsEnabledKey", [self featureName]];
    _storage = storage;
  }
  return self;
}

#pragma mark : - AVAFeatureCommon

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized(self) {
    if ([self isEnabled] != isEnabled) {

      // Persist the enabled status.
      [self.storage setObject:[NSNumber numberWithBool:isEnabled] forKey:self.isEnabledKey];
      [self.storage synchronize];
    }
  }
}

- (BOOL)isEnabled {
  @synchronized(self) {
    /**
     *  Get isEnabled value from persistence.
     * No need to cache the value in a property, user settings already have their cache mechanism.
     */
    NSNumber *isEnabledNumber = [_storage objectForKey:_isEnabledKey];

    // Return the persisted value otherwise it's enabled by default.
    return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
  }
}

- (void)onLogManagerReady:(id<AVALogManager>)logManger {
  self.logManger = logManger;
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [AVAAvalanche sharedInstance].sdkStarted && self.featureInitialised;
  if (!canBeUsed) {
    AVALogError(@"[%@] ERROR: SonomaSDK hasn't been initialized. You need to call [AVAAvalanche "
                @"start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.",
                [self featureName]);
  }
  return canBeUsed;
}

#pragma mark : - AVAFeature

- (void) startFeature {
  self.featureInitialised = YES;
}

+ (void)setEnabled:(BOOL)isEnabled {
  if ([[self sharedInstance] canBeUsed]) {
    [[self sharedInstance] setEnabled:isEnabled];
  }
}

+ (BOOL)isEnabled {
  if ([[self sharedInstance] canBeUsed]) {
    return [[self sharedInstance] isEnabled];
  } else {
    return NO;
  }
}

@end
