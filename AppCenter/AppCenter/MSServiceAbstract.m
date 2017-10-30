#import "MSAppCenterInternal.h"
#import "MSServiceAbstractPrivate.h"

@implementation MSServiceAbstract

@synthesize logManager = _logManager;
@synthesize appSecret = _appSecret;

- (instancetype)init {
  return [self initWithStorage:MS_USER_DEFAULTS];
}

- (instancetype)initWithStorage:(MSUserDefaults *)storage {
  if ((self = [super init])) {
    _started = NO;
    _isEnabledKey = [NSString stringWithFormat:@"kMS%@IsEnabledKey", self.groupId];
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
    [self.storage setObject:@(isEnabled) forKey:self.isEnabledKey];
  }
}

- (void)applyEnabledState:(BOOL)isEnabled {

  // Propagate isEnabled and delete logs on disabled.
  [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES forGroupId:self.groupId];
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [MSAppCenter sharedInstance].sdkConfigured && self.started;
  if (!canBeUsed) {
    MSLogError([MSAppCenter logTag], @"%@ service hasn't been started. You need to call "
                                        @"[MSAppCenter start:YOUR_APP_SECRET withServices:LIST_OF_SERVICES] first.",
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

  // Initialize channel for the service in log manager.
  [self.logManager initChannelWithConfiguration:self.channelConfiguration];

  // Enable this service as needed.
  if (self.isEnabled) {
    [self applyEnabledState:self.isEnabled];
  }
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if (![MSAppCenter isEnabled] && ![MSAppCenter sharedInstance].enabledStateUpdating) {
        MSLogError([MSAppCenter logTag], @"The SDK is disabled. Re-enable the whole SDK from MobileCenter "
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
    return [[self sharedInstance] canBeUsed] && [[self sharedInstance] isEnabled];
  }
}

@end
