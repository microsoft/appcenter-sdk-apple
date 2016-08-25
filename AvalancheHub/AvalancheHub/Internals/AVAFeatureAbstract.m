/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAFeatureAbstract.h"
#import "AVAFeatureAbstractInternal.h"
#import "AVAFeatureAbstractPrivate.h"
#import "AVAUserDefaults.h"
#import "AVAUtils.h"

@implementation AVAFeatureAbstract

@synthesize logManger = _logManager;
@synthesize delegate = _delegate;

- (instancetype)init {
  return [self initWithStorage:kAVAUserDefaults andName:[self featureName]];
}

- (instancetype)initWithStorage:(AVAUserDefaults *)storage andName:(NSString *)name {
  if (self = [super init]) {

    // Construct the storage key.
    _isEnabledKey = [NSString stringWithFormat:@"kAVA%@IsEnabledKey", name];
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

#pragma mark : - AVAFeature

+ (void)setEnabled:(BOOL)isEnabled {
  [[self sharedInstance] setEnabled:isEnabled];
}

+ (BOOL)isEnabled {
  return [[self sharedInstance] isEnabled];
}

@end