#import <Foundation/Foundation.h>

#import "MSAppCenterIngestion.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSLoggerInternal.h"
#import "MSOneCollectorChannelDelegate.h"
#import "MSSessionContext.h"
#import "MSStartServiceLog.h"
#import "MSUserIdContext.h"
#import "MSUtility+StringFormatting.h"

#if !TARGET_OS_TV
#import "MSCustomPropertiesInternal.h"
#import "MSCustomPropertiesLog.h"
#endif

/**
 * Singleton.
 */
static MSAppCenter *sharedInstance = nil;
static dispatch_once_t onceToken;

/**
 * Base URL for HTTP Ingestion backend API calls.
 */
static NSString *const kMSAppCenterBaseUrl = @"https://in.appcenter.ms";

/**
 * Service name for initialization.
 */
static NSString *const kMSServiceName = @"AppCenter";

/**
 * The group Id for storage.
 */
static NSString *const kMSGroupId = @"AppCenter";

/**
 * The minimum storage size, limited by SQLite.
 * 24 KiB to be able to send the default logs (start service, start session, push installation).
 */
static const long kMSMinUpperSizeLimitInBytes = 24 * 1024;

@implementation MSAppCenter

@synthesize installId = _installId;

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSAppCenter alloc] init];
    }
  });
  return sharedInstance;
}

#pragma mark - public

+ (void)configureWithAppSecret:(NSString *)appSecret {

  // 'appSecret' is actually a secret string
  NSString *appSecretOnly = [MSUtility appSecretFrom:appSecret];
  NSString *transmissionTargetToken = [MSUtility transmissionTargetTokenFrom:appSecret];
  [[MSAppCenter sharedInstance] configureWithAppSecret:appSecretOnly transmissionTargetToken:transmissionTargetToken fromApplication:YES];
}

+ (void)configure {
  [[MSAppCenter sharedInstance] configureWithAppSecret:nil transmissionTargetToken:nil fromApplication:YES];
}

+ (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services {

  // 'appSecret' is actually a secret string
  [[MSAppCenter sharedInstance] start:appSecret withServices:services fromApplication:YES];
}

+ (void)startWithServices:(NSArray<Class> *)services {
  [[MSAppCenter sharedInstance] start:nil withServices:services fromApplication:YES];
}

+ (void)startService:(Class)service {
  [[MSAppCenter sharedInstance] startService:service
                               withAppSecret:[[MSAppCenter sharedInstance] appSecret]
                     transmissionTargetToken:[[MSAppCenter sharedInstance] defaultTransmissionTargetToken]
                                  andSendLog:YES
                             fromApplication:YES];
}

+ (void)startFromLibraryWithServices:(NSArray<Class> *)services {
  [[MSAppCenter sharedInstance] start:nil withServices:services fromApplication:NO];
}

+ (BOOL)isConfigured {
  return [[MSAppCenter sharedInstance] sdkConfigured] && [[MSAppCenter sharedInstance] configuredFromApplication];
}

+ (void)setLogUrl:(NSString *)logUrl {
  [[MSAppCenter sharedInstance] setLogUrl:logUrl];
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([MSAppCenter sharedInstance]) {
    if ([[MSAppCenter sharedInstance] canBeUsed]) {
      [[MSAppCenter sharedInstance] setEnabled:isEnabled];
    }
  }
}

+ (BOOL)isEnabled {
  @synchronized([MSAppCenter sharedInstance]) {
    if ([[MSAppCenter sharedInstance] canBeUsed]) {
      return [[MSAppCenter sharedInstance] isEnabled];
    }
  }
  return NO;
}

+ (BOOL)isAppDelegateForwarderEnabled {
  @synchronized([MSAppCenter sharedInstance]) {
    return [MSAppDelegateForwarder sharedInstance].enabled;
  }
}

+ (NSUUID *)installId {
  return [[MSAppCenter sharedInstance] installId];
}

+ (MSLogLevel)logLevel {
  return MSLogger.currentLogLevel;
}

+ (void)setLogLevel:(MSLogLevel)logLevel {
  MSLogger.currentLogLevel = logLevel;

  // The logger is not set at the time of swizzling but now may be a good time to flush the traces.
  [MSDelegateForwarder flushTraceBuffer];
}

+ (void)setLogHandler:(MSLogHandler)logHandler {
  [MSLogger setLogHandler:logHandler];
}

+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk {
  [[MSDeviceTracker sharedInstance] setWrapperSdk:wrapperSdk];
}

#if !TARGET_OS_TV
+ (void)setCustomProperties:(MSCustomProperties *)customProperties {
  [[MSAppCenter sharedInstance] setCustomProperties:customProperties];
}
#endif

/**
 * Check if the debugger is attached
 *
 * Taken from
 * https://github.com/plausiblelabs/plcrashreporter/blob/2dd862ce049e6f43feb355308dfc710f3af54c4d/Source/Crash%20Demo/main.m#L96
 *
 * @return `YES` if the debugger is attached to the current process, `NO` otherwise
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
      NSLog(@"[MSCrashes] ERROR: Checking for a running debugger via sysctl() "
            @"failed.");
      debuggerIsAttached = false;
    }

    if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0) {
      debuggerIsAttached = true;
    }
  });

  return debuggerIsAttached;
}

+ (NSString *)sdkVersion {
  return [MSUtility sdkVersion];
}

+ (NSString *)logTag {
  return kMSServiceName;
}

+ (NSString *)groupId {
  return kMSGroupId;
}

+ (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(void (^)(BOOL))completionHandler {
  [[MSAppCenter sharedInstance] setMaxStorageSize:sizeInBytes completionHandler:completionHandler];
}

+ (void)setUserId:(NSString *)userId {
  [[MSAppCenter sharedInstance] setUserId:userId];
}

#pragma mark - private

- (instancetype)init {
  if ((self = [super init])) {
    _services = [NSMutableArray new];
    _logUrl = kMSAppCenterBaseUrl;
    _enabledStateUpdating = NO;
  }
  return self;
}

/**
 * Configuring without an app secret is valid. If that is the case, the app secret will not be set.
 */
- (BOOL)configureWithAppSecret:(NSString *)appSecret
       transmissionTargetToken:(NSString *)transmissionTargetToken
               fromApplication:(BOOL)fromApplication {
  @synchronized(self) {
    BOOL success = false;
    if (self.configuredFromApplication && fromApplication) {
      MSLogAssert([MSAppCenter logTag], @"App Center SDK has already been configured.");
    } else {
      if (!self.appSecret) {
        self.appSecret = appSecret;

        // Initialize session context.
        // FIXME: It would be better to have obvious way to initialize session context instead of calling setSessionId.
        [[MSSessionContext sharedInstance] setSessionId:nil];
      }
      if (!self.defaultTransmissionTargetToken) {
        self.defaultTransmissionTargetToken = transmissionTargetToken;
      }

      /*
       * Instantiate MSUserIdContext as early as possible to prevent Crashes from using older userId when a newer version of app removes
       * setUserId call from older version of app. MSUserIdContext will handle this one in intializer so we need to make sure
       * MSUserIdContext is initialized before Crashes service processes logs.
       */
      [MSUserIdContext sharedInstance];

      // Init the main pipeline.
      [self initializeChannelGroup];
      [self applyPipelineEnabledState:self.isEnabled];
      self.sdkConfigured = YES;
      self.configuredFromApplication |= fromApplication;

      /*
       * If the log level hasn't been customized before and we are not running in an app store environment, we set the default log level to
       * MSLogLevelWarning.
       */
      if ((![MSLogger isUserDefinedLogLevel]) && ([MSUtility currentAppEnvironment] == MSEnvironmentOther)) {
        [MSAppCenter setLogLevel:MSLogLevelWarning];
      }
      success = true;
    }
    if (success) {
      MSLogInfo([MSAppCenter logTag], @"App Center SDK configured %@successfully.", fromApplication ? @"" : @"from a library ");
    } else {
      MSLogAssert([MSAppCenter logTag], @"App Center SDK configuration %@failed.", fromApplication ? @"" : @"from a library ");
    }
    return success;
  }
}

- (void)start:(NSString *)secretString withServices:(NSArray<Class> *)services fromApplication:(BOOL)fromApplication {
  @synchronized(self) {
    NSString *appSecret = [MSUtility appSecretFrom:secretString];
    NSString *transmissionTargetToken = [MSUtility transmissionTargetTokenFrom:secretString];
    BOOL configured = [self configureWithAppSecret:appSecret
                           transmissionTargetToken:transmissionTargetToken
                                   fromApplication:fromApplication];
    if (configured && services) {
      NSArray *sortedServices = [self sortServices:services];
      MSLogVerbose([MSAppCenter logTag], @"Start services %@ from %@", [sortedServices componentsJoinedByString:@", "],
                   (fromApplication ? @"an application" : @"a library"));
      NSMutableArray<NSString *> *servicesNames = [NSMutableArray arrayWithCapacity:sortedServices.count];
      for (Class service in sortedServices) {
        if ([self startService:service
                          withAppSecret:appSecret
                transmissionTargetToken:transmissionTargetToken
                             andSendLog:NO
                        fromApplication:fromApplication]) {
          [servicesNames addObject:[service serviceName]];
        }
      }
      if ([servicesNames count] > 0) {
        if (fromApplication) {
          [self sendStartServiceLog:servicesNames];
        }
      } else {
        MSLogDebug([MSAppCenter logTag], @"No services have been started.");
      }
    }
  }
}

/**
 * Sort services in descending order to make sure the service with the highest priority gets initialized first. This is intended to make
 * sure Crashes gets initialized first.
 *
 * @param services An array of services.
 */
- (NSArray *)sortServices:(NSArray<Class> *)services {
  if (services && services.count > 1) {
    return [services sortedArrayUsingComparator:^NSComparisonResult(id clazzA, id clazzB) {
#pragma clang diagnostic push

// Ignore "Unknown warning group '-Wobjc-messaging-id'" for old XCode
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wunknown-warning-option"

// Ignore "Messaging unqualified id" for XCode 10
#pragma clang diagnostic ignored "-Wobjc-messaging-id"
      id<MSServiceInternal> serviceA = [clazzA sharedInstance];
      id<MSServiceInternal> serviceB = [clazzB sharedInstance];
#pragma clang diagnostic pop
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

- (BOOL)startService:(Class)clazz
              withAppSecret:(NSString *)appSecret
    transmissionTargetToken:(NSString *)transmissionTargetToken
                 andSendLog:(BOOL)sendLog
            fromApplication:(BOOL)fromApplication {
  @synchronized(self) {

    // Check if clazz is valid class
    if (![clazz conformsToProtocol:@protocol(MSServiceCommon)]) {
      MSLogError([MSAppCenter logTag], @"Cannot start service %@. Provided value is nil or invalid.", clazz);
      return NO;
    }

    // Check if App Center is not configured to start service.
    if (!self.sdkConfigured || (!self.configuredFromApplication && fromApplication)) {
      MSLogError([MSAppCenter logTag], @"App Center has not been configured so it couldn't start the service.");
      return NO;
    }
    id<MSServiceInternal> service = [clazz sharedInstance];
    if (service.isAvailable && fromApplication && service.isStartedFromApplication) {

      // Service already works, we shouldn't send log with this service name
      return NO;
    }
    if (service.isAppSecretRequired && ![appSecret length]) {

      // Service requires an app secret but none is provided.
      MSLogError([MSAppCenter logTag], @"Cannot start service %@. App Center was started without app secret, but the service requires it.",
                 clazz);
      return NO;
    }

    // Check if service should be disabled
    if ([self shouldDisable:[clazz serviceName]]) {
      MSLogDebug([MSAppCenter logTag], @"Environment variable to disable service has been set; not starting service %@", clazz);
      return NO;
    }

    if (!service.isAvailable) {

      // Set appCenterDelegate.
      [self.services addObject:service];

      // Start service with channel group.
      [service startWithChannelGroup:self.channelGroup
                           appSecret:appSecret
             transmissionTargetToken:transmissionTargetToken
                     fromApplication:fromApplication];

      // Disable service if AppCenter is disabled.
      if ([clazz isEnabled] && !self.isEnabled) {
        self.enabledStateUpdating = YES;
        [clazz setEnabled:NO];
        self.enabledStateUpdating = NO;
      }
    } else if (fromApplication) {
      [service updateConfigurationWithAppSecret:appSecret transmissionTargetToken:transmissionTargetToken];
    }

    // Send start service log.
    if (sendLog && fromApplication) {
      [self sendStartServiceLog:@[ [clazz serviceName] ]];
    }

    // Service started.
    return YES;
  }
}

- (void)setLogUrl:(NSString *)logUrl {
  @synchronized(self) {
    _logUrl = logUrl;
    if (self.channelGroup) {
      [self.channelGroup setLogUrl:logUrl];
    }
  }
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(void (^)(BOOL))completionHandler {

  // Check if sizeInBytes is greater than minimum size.
  if (sizeInBytes < kMSMinUpperSizeLimitInBytes) {
    if (completionHandler) {
      completionHandler(NO);
    }
    MSLogWarning([MSAppCenter logTag], @"Cannot set storage size to %ld bytes, minimum value is %ld bytes", sizeInBytes,
                 kMSMinUpperSizeLimitInBytes);
    return;
  }

  // Change the max storage size.
  BOOL setMaxSizeFailed = NO;
  @synchronized(self) {
    if (self.setMaxStorageSizeHasBeenCalled) {
      MSLogWarning([MSAppCenter logTag], @"setMaxStorageSize:completionHandler: may only be called once per app launch");
      setMaxSizeFailed = YES;
    } else {
      self.setMaxStorageSizeHasBeenCalled = YES;
      if (self.configuredFromApplication) {
        MSLogWarning([MSAppCenter logTag], @"Unable to set storage size after the application has configured App Center");
        setMaxSizeFailed = YES;
      } else {
        self.requestedMaxStorageSizeInBytes = @(sizeInBytes);
        self.maxStorageSizeCompletionHandler = completionHandler;
        if (self.channelGroup) {
          [self.channelGroup setMaxStorageSize:sizeInBytes completionHandler:self.maxStorageSizeCompletionHandler];
        }
      }
    }
  }
  if (setMaxSizeFailed && completionHandler) {
    completionHandler(NO);
  }
}

- (void)setUserId:(NSString *)userId {
  if (!self.configuredFromApplication) {
    MSLogError([MSAppCenter logTag], @"AppCenter must be configured from application, libraries cannot use call setUserId.");
    return;
  }
  if (!self.appSecret && !self.defaultTransmissionTargetToken) {
    MSLogError([MSAppCenter logTag], @"AppCenter must be configured with a secret from application to call setUserId.");
    return;
  }
  if (userId) {
    if (self.appSecret && ![MSUserIdContext isUserIdValidForAppCenter:userId]) {
      return;
    }
    if (self.defaultTransmissionTargetToken && ![MSUserIdContext isUserIdValidForOneCollector:userId]) {
      return;
    }
  }
  [[MSUserIdContext sharedInstance] setUserId:userId];
}

#if !TARGET_OS_TV
- (void)setCustomProperties:(MSCustomProperties *)customProperties {
  NSDictionary<NSString *, NSObject *> *propertiesCopy = [customProperties propertiesImmutableCopy];
  if (!customProperties || (propertiesCopy.count == 0)) {
    MSLogError([MSAppCenter logTag], @"Custom properties may not be null or empty");
    return;
  }
  [self sendCustomPropertiesLog:propertiesCopy];
}
#endif

- (void)setEnabled:(BOOL)isEnabled {
  self.enabledStateUpdating = YES;
  if ([self isEnabled] != isEnabled) {

    // Persist the enabled status.
    [MS_USER_DEFAULTS setObject:@(isEnabled) forKey:kMSAppCenterIsEnabledKey];

    // Enable/disable pipeline.
    [self applyPipelineEnabledState:isEnabled];
  }

  // Propagate enable/disable on all services.
  for (id<MSServiceInternal> service in self.services) {
    [[service class] setEnabled:isEnabled];
  }
  self.enabledStateUpdating = NO;
  MSLogInfo([MSAppCenter logTag], @"App Center SDK %@.", isEnabled ? @"enabled" : @"disabled");
}

- (BOOL)isEnabled {

  /*
   * Get isEnabled value from persistence.
   * No need to cache the value in a property, user settings already have their cache mechanism.
   */
  NSNumber *isEnabledNumber = [MS_USER_DEFAULTS objectForKey:kMSAppCenterIsEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)applyPipelineEnabledState:(BOOL)isEnabled {

  // Remove all notification handlers.
  [MS_NOTIFICATION_CENTER removeObserver:self];

  // Hookup to application life-cycle events.
  if (isEnabled) {
#if !TARGET_OS_OSX
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
#endif
  } else {

    // Clean session, device and userId history in case we are disabled.
    [[MSDeviceTracker sharedInstance] clearDevices];
    [[MSSessionContext sharedInstance] clearSessionHistoryAndKeepCurrentSession:NO];
    [[MSUserIdContext sharedInstance] clearUserIdHistory];
  }

  // Propagate to channel group.
  [self.channelGroup setEnabled:isEnabled andDeleteDataOnDisabled:YES];

  // Send started services.
  if (self.startedServiceNames && isEnabled) {
    [self sendStartServiceLog:self.startedServiceNames];
    self.startedServiceNames = nil;
  }
}

- (void)initializeChannelGroup {

  // Construct channel group.
  self.oneCollectorChannelDelegate =
      self.oneCollectorChannelDelegate ?: [[MSOneCollectorChannelDelegate alloc] initWithInstallId:self.installId];
  if (!self.channelGroup) {
    self.channelGroup = [[MSChannelGroupDefault alloc] initWithInstallId:self.installId logUrl:self.logUrl];
    [self.channelGroup addDelegate:self.oneCollectorChannelDelegate];
    if (self.requestedMaxStorageSizeInBytes) {
      long storageSize = [self.requestedMaxStorageSizeInBytes longValue];
      [self.channelGroup setMaxStorageSize:storageSize completionHandler:self.maxStorageSizeCompletionHandler];
    }
  }
  [self.channelGroup setAppSecret:self.appSecret];

  // Initialize a channel unit for start service logs.
  self.channelUnit =
      self.channelUnit
          ?: [self.channelGroup addChannelUnitWithConfiguration:[[MSChannelUnitConfiguration alloc]
                                                                    initDefaultConfigurationWithGroupId:[MSAppCenter groupId]]];
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
    MSLogError([MSAppCenter logTag], @"App Center SDK hasn't been configured. You need to call [MSAppCenter start:YOUR_APP_SECRET "
                                     @"withServices:LIST_OF_SERVICES] first.");
  }
  return canBeUsed;
}

- (void)sendStartServiceLog:(NSArray<NSString *> *)servicesNames {
  if (self.isEnabled) {
    MSStartServiceLog *serviceLog = [MSStartServiceLog new];
    serviceLog.services = servicesNames;
    [self.channelUnit enqueueItem:serviceLog flags:MSFlagsDefault];
  } else {
    if (self.startedServiceNames == nil) {
      self.startedServiceNames = [NSMutableArray new];
    }
    [self.startedServiceNames addObjectsFromArray:servicesNames];
  }
}

#if !TARGET_OS_TV
- (void)sendCustomPropertiesLog:(NSDictionary<NSString *, NSObject *> *)properties {
  MSCustomPropertiesLog *customPropertiesLog = [MSCustomPropertiesLog new];
  customPropertiesLog.properties = properties;
  [self.channelUnit enqueueItem:customPropertiesLog flags:MSFlagsDefault];
}
#endif

+ (void)resetSharedInstance {
  onceToken = 0; // resets the once_token so dispatch_once will run again
  sharedInstance = nil;
}

#pragma mark - Application life cycle

#if !TARGET_OS_OSX
/**
 *  The application will go to the foreground.
 */
- (void)applicationWillEnterForeground {
  [self.channelGroup resumeWithIdentifyingObject:self];
}

/**
 *  The application will go to the background.
 */
- (void)applicationDidEnterBackground {
  [self.channelGroup pauseWithIdentifyingObject:self];
}
#endif

#pragma mark - Disable services for test cloud

/**
 * Determines whether a service should be disabled.
 *
 * @param serviceName The service name to consider for disabling.
 *
 * @return YES if the service should be disabled.
 */
- (BOOL)shouldDisable:(NSString *)serviceName {
  NSDictionary *environmentVariables = [[NSProcessInfo processInfo] environment];
  NSString *disabledServices = environmentVariables[kMSDisableVariable];
  if (!disabledServices) {
    return NO;
  }
  NSMutableArray *disabledServicesList = [NSMutableArray arrayWithArray:[disabledServices componentsSeparatedByString:@","]];

  // Trim whitespace characters.
  for (NSUInteger i = 0; i < [disabledServicesList count]; ++i) {
    NSString *service = disabledServicesList[i];
    service = [service stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    disabledServicesList[i] = service;
  }
  return [disabledServicesList containsObject:serviceName] || [disabledServicesList containsObject:kMSDisableAll];
}

@end
