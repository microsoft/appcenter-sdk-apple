#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSConstants+Internal.h"
#import "MSDeviceTracker.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSHttpSender.h"
#import "MSLogManagerDefault.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSStartServiceLog.h"
#if !TARGET_OS_TV
#import "MSCustomProperties.h"
#import "MSCustomPropertiesLog.h"
#import "MSCustomPropertiesPrivate.h"
#endif

// Singleton
static MSMobileCenter *sharedInstance = nil;
static dispatch_once_t onceToken;

/**
 * Base URL for HTTP Ingestion backend API calls.
 */
static NSString *const kMSDefaultBaseUrl = @"https://in.mobile.azure.com";

// Service name for initialization.
static NSString *const kMSServiceName = @"MobileCenter";

// The group Id for storage.
static NSString *const kMSGroupId = @"MobileCenter";

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
  [[self sharedInstance] startService:service andSendLog:YES];
}

+ (BOOL)isConfigured {
  return [[self sharedInstance] sdkConfigured];
}

+ (void)setLogUrl:(NSString *)logUrl {
  [[self sharedInstance] setLogUrl:logUrl];
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

+ (BOOL)isAppDelegateForwarderEnabled {
  @synchronized([self sharedInstance]) {
    return MSAppDelegateForwarder.enabled;
  }
}

+ (NSUUID *)installId {
  return [[self sharedInstance] installId];
}

+ (MSLogLevel)logLevel {
  return MSLogger.currentLogLevel;
}

+ (void)setLogLevel:(MSLogLevel)logLevel {
  MSLogger.currentLogLevel = logLevel;

  // The logger is not set at the time of swizzling but now may be a good time to flush the traces.
  [MSAppDelegateForwarder flushTraceBuffer];
}

+ (void)setLogHandler:(MSLogHandler)logHandler {
  [MSLogger setLogHandler:logHandler];
}

+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk {
  [[MSDeviceTracker sharedInstance] setWrapperSdk:wrapperSdk];
}

#if !TARGET_OS_TV
+ (void)setCustomProperties:(MSCustomProperties *)customProperties {
  [[self sharedInstance] setCustomProperties:customProperties];
}
#endif

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
  return kMSServiceName;
}

#pragma mark - private

- (instancetype)init {
  if ((self = [super init])) {
    _services = [NSMutableArray new];
    _logUrl = kMSDefaultBaseUrl;
    _enabledStateUpdating = NO;
  }
  return self;
}

- (BOOL)configure:(NSString *)appSecret {
  @synchronized(self) {
    BOOL success = false;
    if (self.sdkConfigured) {
      MSLogAssert([MSMobileCenter logTag], @"Mobile Center SDK has already been configured.");
    }

    // Validate and set the app secret.
    else if ([appSecret length] == 0) {
      MSLogAssert([MSMobileCenter logTag], @"AppSecret is invalid.");
    } else {
      self.appSecret = appSecret;

      // Init the main pipeline.
      [self initializeLogManager];

      // Enable pipeline as needed.
      if (self.isEnabled) {
        [self applyPipelineEnabledState:self.isEnabled];
      }

      self.sdkConfigured = YES;

      /*
       * If the loglevel hasn't been customized before and we are not running in an app store environment,
       * we set the default loglevel to MSLogLevelWarning.
       */
      if ((![MSLogger isUserDefinedLogLevel]) && ([MSUtility currentAppEnvironment] == MSEnvironmentOther)) {
        [MSMobileCenter setLogLevel:MSLogLevelWarning];
      }
      success = true;
    }
    MSLogAssert([MSMobileCenter logTag], @"Mobile Center SDK %@",
                (success) ? @"configured successfully." : @"configuration failed.");
    return success;
  }
}

- (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services {
  @synchronized(self) {
    BOOL configured = [self configure:appSecret];
    if (configured && services) {
      NSArray *sortedServices = [self sortServices:services];
      NSMutableArray<NSString *> *servicesNames = [NSMutableArray arrayWithCapacity:sortedServices.count];

      for (Class service in sortedServices) {
        if ([self startService:service andSendLog:NO]) {
          [servicesNames addObject:[service serviceName]];
        }
      }
      if ([servicesNames count] > 0) {
        [self sendStartServiceLog:servicesNames];
      } else {
        MSLogDebug([MSMobileCenter logTag], @"No services have been started.");
      }
    }
  }
}

/**
 * Sort services in descending order to make sure the service with the highest priority gets initialized first.
 * This is intended to make sure Crashes gets initialized first.
 */
- (NSArray *)sortServices:(NSArray<Class> *)services {
  if (services && services.count > 1) {
    return [services sortedArrayUsingComparator:^NSComparisonResult(id clazzA, id clazzB) {
      id<MSServiceInternal> serviceA = [clazzA sharedInstance];
      id<MSServiceInternal> serviceB = [clazzB sharedInstance];
      if (serviceA.initializationPriority < serviceB.initializationPriority) {
        return NSOrderedDescending;
      } else {
        return NSOrderedAscending;
      }
    }];
  } else {
    return services;
  }
}

- (BOOL)startService:(Class)clazz andSendLog:(BOOL)sendLog {
  @synchronized(self) {

    // Check if clazz is valid class
    if (![clazz conformsToProtocol:@protocol(MSServiceCommon)]) {
      MSLogError([MSMobileCenter logTag], @"Cannot start service %@. Provided value is nil or invalid.", clazz);
      return NO;
    }
    id<MSServiceInternal> service = [clazz sharedInstance];
    if (service.isAvailable) {

      // Service already works, we shouldn't send log with this service name
      return NO;
    }

    // Set mobileCenterDelegate.
    [self.services addObject:service];

    // Start service with log manager.
    [service startWithLogManager:self.logManager appSecret:self.appSecret];

    // Send start service log.
    if (sendLog) {
      [self sendStartServiceLog:@[ [clazz serviceName] ]];
    }

    // Service started.
    return YES;
  }
}

- (void)setLogUrl:(NSString *)logUrl {
  @synchronized(self) {
    _logUrl = logUrl;
    if (self.logManager) {
      [self.logManager setLogUrl:logUrl];
    }
  }
}

#if !TARGET_OS_TV
- (void)setCustomProperties:(MSCustomProperties *)customProperties {
  if (!customProperties || customProperties.properties == 0) {
    MSLogError([MSMobileCenter logTag], @"Custom properties may not be null or empty");
    return;
  }
  [self sendCustomPropertiesLog:customProperties.properties];
}
#endif

- (void)setEnabled:(BOOL)isEnabled {
  self.enabledStateUpdating = YES;
  if ([self isEnabled] != isEnabled) {

    // Enable/disable pipeline.
    [self applyPipelineEnabledState:isEnabled];

    // Persist the enabled status.
    [MS_USER_DEFAULTS setObject:@(isEnabled) forKey:kMSMobileCenterIsEnabledKey];
  }

  // Propagate enable/disable on all services.
  for (id<MSServiceInternal> service in self.services) {
    [[service class] setEnabled:isEnabled];
  }
  self.enabledStateUpdating = NO;
  MSLogInfo([MSMobileCenter logTag], @"Mobile Center SDK %@.", isEnabled ? @"enabled" : @"disabled");
}

- (BOOL)isEnabled {

  /*
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
    [self addObservers];
  } else {

    // Clean device history in case we are disabled.
    [[MSDeviceTracker sharedInstance] clearDevices];
  }

  // Propagate to log manager.
  [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES];
}

- (void)initializeLogManager {

  // Construct log manager.
  self.logManager =
      [[MSLogManagerDefault alloc] initWithAppSecret:self.appSecret installId:self.installId logUrl:self.logUrl];

  // Initialize a channel for start service logs.
  [self.logManager
      initChannelWithConfiguration:[[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:kMSGroupId]];
}

- (NSString *)appSecret {
  return _appSecret;
}

- (NSUUID *)installId {
  @synchronized(self) {
    if (!_installId) {

      // Check if install Id has already been persisted.
      NSString *savedInstallId = [MS_USER_DEFAULTS objectForKey:kMSInstallIdKey];
      if (savedInstallId) {
        _installId = MS_UUID_FROM_STRING(savedInstallId);
      }

      // Create a new random install Id if persistence failed.
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

- (void)sendStartServiceLog:(NSArray<NSString *> *)servicesNames {
  MSStartServiceLog *serviceLog = [MSStartServiceLog new];
  serviceLog.services = servicesNames;
  [self.logManager processLog:serviceLog forGroupId:kMSGroupId];
}

#if !TARGET_OS_TV
- (void)sendCustomPropertiesLog:(NSDictionary<NSString *, NSObject *> *)properties {
  MSCustomPropertiesLog *customPropertiesLog = [MSCustomPropertiesLog new];
  customPropertiesLog.properties = properties;

  // FIXME: withPriority parameter need to be removed on merge.
  [self.logManager processLog:customPropertiesLog forGroupId:kMSGroupId];
}
#endif

+ (void)resetSharedInstance {
  onceToken = 0; // resets the once_token so dispatch_once will run again
  sharedInstance = nil;
}

#pragma mark - Application life cycle

/**
 *  The application will go to the foreground.
 */
- (void)applicationWillEnterForeground {

  /**
   * Triggering a resume here to make sure our pipeline is working. While it won't be suspended when going into the
   * background anymore, it might be suspended because we're offline or it failed to send events.
   */
  [self.logManager resume];
}

- (void)dealloc {
  [self removeObservers];
}

#pragma mark - Observers

- (void)addObservers {
#if TARGET_OS_OSX
  [MS_NOTIFICATION_CENTER addObserver:self
                             selector:@selector(applicationWillEnterForeground)
                                 name:NSApplicationDidUnhideNotification
                               object:nil];
#else
  [MS_NOTIFICATION_CENTER addObserver:self
                             selector:@selector(applicationWillEnterForeground)
                                 name:UIApplicationWillEnterForegroundNotification
                               object:nil];
#endif
}

- (void)removeObservers {
#if TARGET_OS_OSX
  [MS_NOTIFICATION_CENTER removeObserver:self name:NSApplicationDidUnhideNotification object:nil];
#else
  [MS_NOTIFICATION_CENTER removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
}

@end
