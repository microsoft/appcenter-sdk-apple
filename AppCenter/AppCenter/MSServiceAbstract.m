#import "MSAppCenterInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSServiceAbstractPrivate.h"

@implementation MSServiceAbstract

@synthesize channelGroup = _channelGroup;
@synthesize channelUnit = _channelUnit;
@synthesize appSecret = _appSecret;
@synthesize defaultTransmissionTargetToken = _defaultTransmissionTargetToken;

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
  [self.channelUnit setEnabled:isEnabled andDeleteDataOnDisabled:YES];
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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup appSecret:(NSString *)appSecret transmissionTargetToken:(NSString *)token {
  self.channelGroup = channelGroup;
  self.appSecret = appSecret;
  self.defaultTransmissionTargetToken = token;
  self.started = YES;
  if ([self respondsToSelector:@selector(channelUnitConfiguration)]) {

    // Initialize channel unit for the service in log manager.
    self.channelUnit = [self.channelGroup addChannelUnitWithConfiguration:self.channelUnitConfiguration];
  }

  // Enable this service as needed.
  if (self.isEnabled) {
    [self applyEnabledState:self.isEnabled];
  }
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if (![MSAppCenter isEnabled] && ![MSAppCenter sharedInstance].enabledStateUpdating) {
        MSLogError([MSAppCenter logTag], @"The SDK is disabled. Re-enable the whole SDK from AppCenter "
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
