#import "MSMobileCenterInternal.h"
#import "MSServiceAbstractPrivate.h"

@implementation MSServiceAbstract

@synthesize logManager = _logManager;
@synthesize appSecret = _appSecret;

- (instancetype)init {
  return [self initWithStorage:MS_USER_DEFAULTS];
}

- (instancetype)initWithStorage:(MSUserDefaults *)storage {
  if (self = [super init]) {
    _started = NO;
    _isEnabledKey = [NSString stringWithFormat:@"kMS%@IsEnabledKey", self.storageKey];
    _storage = storage;
  }
  return self;
}

#pragma mark : - MSServiceCommon

- (BOOL)isEnabled {

  // Get isEnabled value from persistence.
  // No need to cache the value in a property, user settings already have their cache mechanism.
  NSNumber *isEnabledNumber = [self.storage objectForKey:self.isEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)setEnabled:(BOOL)isEnabled {
  if (self.isEnabled != isEnabled) {

    // Apply enabled state.
    [self applyEnabledState:isEnabled];

    // Persist the enabled status.
    [self.storage setObject:[NSNumber numberWithBool:isEnabled] forKey:self.isEnabledKey];
  }
}

- (void)applyEnabledState:(BOOL)isEnabled {

  // Propagate isEnabled and delete logs on disabled.
  [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES forPriority:self.priority];
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [MSMobileCenter sharedInstance].sdkConfigured && self.started;
  if (!canBeUsed) {
    MSLogError([MSMobileCenter logTag], @"%@ service hasn't been started. You need to call "
                                        @"[MSMobileCenter start:YOUR_APP_SECRET withServices:LIST_OF_SERVICES] first.",
               MS_CLASS_NAME_WITHOUT_PREFIX);
  }
  return canBeUsed;
}

- (BOOL)isAvailable {
  return self.isEnabled && self.started;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

#pragma mark : - MSService

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  self.started = YES;
  self.logManager = logManager;
  self.appSecret = appSecret;

  // Enable this service as needed.
  if (self.isEnabled) {
    [self applyEnabledState:self.isEnabled];
  }
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if (![MSMobileCenter isEnabled] && ![MSMobileCenter sharedInstance].enabledStateUpdating) {
        MSLogError([MSMobileCenter logTag], @"The SDK is disabled. Re-enable the whole SDK from MobileCenter "
                                            @"first before enabling %@ service.",
                   MS_CLASS_NAME_WITHOUT_PREFIX);
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
