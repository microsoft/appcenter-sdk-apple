/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSonomaInternal.h"
#import "SNMFeatureAbstract.h"
#import "SNMFeatureAbstractInternal.h"
#import "SNMFeatureAbstractPrivate.h"
#import "SNMUserDefaults.h"
#import "SNMUtils.h"
#import "SonomaCore+Internal.h"

@implementation SNMFeatureAbstract

@synthesize logManger = _logManager;
@synthesize delegate = _delegate;

- (instancetype)init {
  return [self initWithStorage:kSNMUserDefaults];
}

- (instancetype)initWithStorage:(SNMUserDefaults *)storage {
  if (self = [super init]) {

    _isEnabledKey = [NSString stringWithFormat:@"kSNM%@IsEnabledKey", [self featureName]];
    _storage = storage;
  }
  return self;
}

#pragma mark : - SNMFeatureCommon

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized(self) {
    if ([self isEnabled] != isEnabled) {

      // Persist the enabled status.
      [self.storage setObject:[NSNumber numberWithBool:isEnabled] forKey:self.isEnabledKey];
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

- (void)onLogManagerReady:(id<SNMLogManager>)logManger {
  self.logManger = logManger;
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [SNMSonoma sharedInstance].sdkStarted && self.featureInitialised;
  if (!canBeUsed) {
    SNMLogError(@"[%@] ERROR: SonomaSDK hasn't been initialized. You need to call [SNMSonoma "
                @"start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.",
                [self featureName]);
  }
  return canBeUsed;
}

#pragma mark : - SNMFeature

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
