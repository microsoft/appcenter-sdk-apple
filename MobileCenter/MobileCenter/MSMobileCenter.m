#import "MSConstants+Internal.h"
#import "MSDeviceTracker.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSFileStorage.h"
#import "MSHttpSender.h"
#import "MSLogManagerDefault.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"

// Singleton
static MSMobileCenter *sharedInstance = nil;
static dispatch_once_t onceToken;

// Base URL for HTTP backend API calls.
static NSString *const kMSDefaultBaseUrl = @"https://in.mobile.azure.com";

@implementation MSMobileCenter

@synthesize installId = _installId;

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
    }
  });
  return sharedInstance;
}

#pragma mark - public

+ (void)configureWithAppSecret:(NSString *)appSecret {
  [[self sharedInstance] configure:appSecret];
}

+ (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services {
  [[self sharedInstance] start:appSecret withServices:services];
}

+ (void)startService:(Class)service {
  [[self sharedInstance] startService:service];
}

+ (BOOL)isConfigured {
  return [[self sharedInstance] sdkConfigured];
}

+ (void)setServerUrl:(NSString *)serverUrl {
  [[self sharedInstance] setServerUrl:serverUrl];
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      [[self sharedInstance] setEnabled:isEnabled];
    }
  }
}

+ (BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      return [[self sharedInstance] isEnabled];
    }
  }
  return NO;
}

+ (NSUUID *)installId {
  return [[self sharedInstance] installId];
}

+ (MSLogLevel)logLevel {
  return MSLogger.currentLogLevel;
}

+ (void)setLogLevel:(MSLogLevel)logLevel {
  MSLogger.currentLogLevel = logLevel;
}

+ (void)setLogHandler:(MSLogHandler)logHandler {
  [MSLogger setLogHandler:logHandler];
}

+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk {
  [MSDeviceTracker setWrapperSdk:wrapperSdk];
}

/**
 * Check if the debugger is attached
 *
 * Taken from
 * https://github.com/plausiblelabs/plcrashreporter/blob/2dd862ce049e6f43feb355308dfc710f3af54c4d/Source/Crash%20Demo/main.m#L96
 *
 * @return `YES` if the debugger is attached to the current process, `NO`
 * otherwise
 */
+ (BOOL)isDebuggerAttached {
  static BOOL debuggerIsAttached = NO;

  static dispatch_once_t debuggerPredicate;
  dispatch_once(&debuggerPredicate, ^{
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int name[4];

    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();

    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
      NSLog(@"[MSCrashes] ERROR: Checking for a running debugger via sysctl() failed.");
      debuggerIsAttached = false;
    }

    if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
      debuggerIsAttached = true;
  });

  return debuggerIsAttached;
}

+ (NSString *)logTag {
  return @"MobileCenter";
}

#pragma mark - private

- (instancetype)init {
  if (self = [super init]) {
    _services = [NSMutableArray new];
    _serverUrl = kMSDefaultBaseUrl;
    _enabledStateUpdating = NO;
  }
  return self;
}

- (BOOL)configure:(NSString *)appSecret {
  BOOL success = false;
  if (self.sdkConfigured) {
    MSLogAssert([MSMobileCenter logTag], @"Mobile Center SDK has already been configured.");
  }

  // Validate and set the app secret.
  else if ([appSecret length] == 0) {
    MSLogAssert([MSMobileCenter logTag], @"AppSecret is invalid.");
  } else {
    self.appSecret = appSecret;

    // Set backend API version.
    self.apiVersion = kMSAPIVersion;

    // Init the main pipeline.
    [self initializeLogManager];

    // Enable pipeline as needed.
    if (self.isEnabled) {
      [self applyPipelineEnabledState:self.isEnabled];
    }

    _sdkConfigured = YES;

    // If the loglevel hasn't been customized before and we are not running in an app store environment, we set the
    // default loglevel to MSLogLevelWarning.
    if ((![MSLogger isUserDefinedLogLevel]) && ([MSUtil currentAppEnvironment] == MSEnvironmentOther)) {
      [MSMobileCenter setLogLevel:MSLogLevelWarning];
    }
    success = true;
  }
  MSLogAssert([MSMobileCenter logTag], @"Mobile Center SDK %@",
              (success) ? @"configured successfully." : @"configuration failed.");
  return success;
}

- (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services {
  BOOL configured = [self configure:appSecret];
  if (configured) {
    for (Class service in services) {
      [self startService:service];
    }
  }
}

- (void)startService:(Class)clazz {
  id<MSServiceInternal> service = [clazz sharedInstance];

  // Set mobileCenterDelegate.
  [self.services addObject:service];

  // Start service with log manager.
  [service startWithLogManager:self.logManager appSecret:self.appSecret];
}

- (void)setServerUrl:(NSString *)serverUrl {
  @synchronized(self) {
    _serverUrl = serverUrl;
  }
}

- (void)setEnabled:(BOOL)isEnabled {
  self.enabledStateUpdating = YES;
  if ([self isEnabled] != isEnabled) {

    // Enable/disable pipeline.
    [self applyPipelineEnabledState:isEnabled];

    // Persist the enabled status.
    [MS_USER_DEFAULTS setObject:[NSNumber numberWithBool:isEnabled] forKey:kMSMobileCenterIsEnabledKey];
  }

  // Propagate enable/disable on all services.
  for (id<MSServiceInternal> service in self.services) {
    [[service class] setEnabled:isEnabled];
  }
  self.enabledStateUpdating = NO;
  MSLogInfo([MSMobileCenter logTag], @"Mobile Center SDK %@.", isEnabled ? @"enabled" : @"disabled");
}

- (BOOL)isEnabled {

  /**
   * Get isEnabled value from persistence.
   * No need to cache the value in a property, user settings already have their cache mechanism.
   */
  NSNumber *isEnabledNumber = [MS_USER_DEFAULTS objectForKey:kMSMobileCenterIsEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)applyPipelineEnabledState:(BOOL)isEnabled {

  // Remove all notification handlers
  [MS_NOTIFICATION_CENTER removeObserver:self];

  // Hookup to application life-cycle events
  if (isEnabled) {
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
  }

  // Propagate to log manager.
  [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES];
}

- (void)initializeLogManager {

  // Construct log manager.
  _logManager =
      [[MSLogManagerDefault alloc] initWithAppSecret:self.appSecret installId:self.installId serverUrl:self.serverUrl];
}

- (NSString *)appSecret {
  return _appSecret;
}

- (NSString *)apiVersion {
  return _apiVersion;
}

- (NSUUID *)installId {
  @synchronized(self) {
    if (!_installId) {

      // Check if install Id has already been persisted.
      NSString *savedInstallId = [MS_USER_DEFAULTS objectForKey:kMSInstallIdKey];
      if (savedInstallId) {
        _installId = MS_UUID_FROM_STRING(savedInstallId);
      }

      // Create a new random install Id if persistency failed.
      if (!_installId) {
        _installId = [NSUUID UUID];

        // Persist the install Id string.
        [MS_USER_DEFAULTS setObject:[_installId UUIDString] forKey:kMSInstallIdKey];
      }
    }
    return _installId;
  }
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = self.sdkConfigured;
  if (!canBeUsed) {
    MSLogError([MSMobileCenter logTag], @"Mobile Center SDK hasn't been configured. You need to call [MSMobileCenter "
                                        @"start:YOUR_APP_SECRET withServices:LIST_OF_SERVICES] first.");
  }
  return canBeUsed;
}

+ (void)resetSharedInstance {
  onceToken = 0; // resets the once_token so dispatch_once will run again
  sharedInstance = nil;
}

#pragma mark - Application life cycle

/**
 *  The application will go to the foreground.
 */
- (void)applicationWillEnterForeground {
  [self.logManager setEnabled:YES andDeleteDataOnDisabled:NO];
}

/**
 *  The application will go to the background.
 */
- (void)applicationDidEnterBackground {
  [self.logManager setEnabled:NO andDeleteDataOnDisabled:NO];
}

@end
