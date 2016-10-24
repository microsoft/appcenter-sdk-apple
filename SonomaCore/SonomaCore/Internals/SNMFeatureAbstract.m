/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMFeatureAbstract.h"
#import "SNMFeatureAbstractInternal.h"
#import "SNMFeatureAbstractPrivate.h"
#import "SNMSonomaInternal.h"

@implementation SNMFeatureAbstract

@synthesize logManager = _logManager;

- (instancetype)init {
  return [self initWithStorage:kSNMUserDefaults];
}

- (instancetype)initWithStorage:(SNMUserDefaults *)storage {
  if (self = [super init]) {

    _isEnabledKey = [NSString stringWithFormat:@"kSNM%@IsEnabledKey", self.storageKey];
    _storage = storage;
  }
  return self;
}

#pragma mark : - SNMFeatureCommon

- (void)setEnabled:(BOOL)isEnabled {

  // Propagate isEnabled and delete logs on disabled.
  if (self.logManager) {
    [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES forPriority:self.priority];
  }

  // Persist the enabled status.
  [self.storage setObject:[NSNumber numberWithBool:isEnabled] forKey:self.isEnabledKey];
}

- (BOOL)isEnabled {
  /**
   *  Get isEnabled value from persistence.
   * No need to cache the value in a property, user settings already have their cache mechanism.
   */
  NSNumber *isEnabledNumber = [_storage objectForKey:_isEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)onLogManagerReady:(id<SNMLogManager>)logManager {
  self.logManager = logManager;
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [SNMSonoma sharedInstance].sdkStarted && self.featureInitialized;
  if (!canBeUsed) {
    SNMLogError([SNMSonoma getLoggerTag],
                @"%@ module hasn't been initialized. You need to call "
                @"[SNMSonoma start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.",
                CLASS_NAME_WITHOUT_PREFIX);
  }
  return canBeUsed;
}

#pragma mark : - SNMFeature

- (void)startFeature {
  self.featureInitialized = YES;

  // Send pending logs if persistence has logs that are not sent yet
  [self.logManager flushPendingLogsForPriority:self.priority];
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed] && [[self sharedInstance] isEnabled] != isEnabled) {
      if (![SNMSonoma isEnabled] && ![SNMSonoma sharedInstance].enabledStateUpdating) {
        SNMLogError([SNMSonoma getLoggerTag],
                    @"The SDK is disabled. Re-enable the SDK from the core module "
                    @"first before enabling %@ feature.",
                    CLASS_NAME_WITHOUT_PREFIX);
      } else {
        [[self sharedInstance] setEnabled:isEnabled];
      }
    }
  }
}

+ (BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      return [[self sharedInstance] isEnabled];
    } else {
      return NO;
    }
  }
}

@end
