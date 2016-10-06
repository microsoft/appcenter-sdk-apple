#import "SNMConstants+Internal.h"
#import "SNMEnvironmentHelper.h"
#import "SNMFileStorage.h"
#import "SNMHttpSender.h"
#import "SNMLogManagerDefault.h"
#import "SNMLoggerPrivate.h"
#import "SNMSonomaInternal.h"
#import "SNMUserDefaults.h"
#import "SNMUtils.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

// Http Headers + Query string.
static NSString *const kSNMHeaderAppSecretKey = @"App-Secret";
static NSString *const kSNMHeaderInstallIDKey = @"Install-ID";
static NSString *const kSNMHeaderContentTypeKey = @"Content-Type";
static NSString *const kSNMContentType = @"application/json";
static NSString *const kSNMAPIVersion = @"1.0.0-preview20160914";
static NSString *const kSNMAPIVersionKey = @"api_version";

// Base URL for HTTP backend API calls.
static NSString *const kSNMDefaultBaseUrl = @"http://in-integration.dev.avalanch.es:8081";

@implementation SNMSonoma

@synthesize installId = _installId;

+ (instancetype)sharedInstance {
  static SNMSonoma *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

#pragma mark - public

+ (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features {
  [[self sharedInstance] start:appSecret withFeatures:features];
}

+ (void)setServerUrl:(NSString *)serverUrl {
  [[self sharedInstance] setServerUrl:serverUrl];
}

+ (void)setEnabled:(BOOL)isEnabled {
  [[self sharedInstance] setEnabled:isEnabled];
}

+ (BOOL)isEnabled {
  return [[self sharedInstance] isEnabled];
}

+ (NSUUID *)installId {
  return [[self sharedInstance] installId];
}

+ (SNMLogLevel)logLevel {
  return SNMLogger.currentLogLevel;
}

+ (void)setLogLevel:(SNMLogLevel)logLevel {
  SNMLogger.currentLogLevel = logLevel;
}

+ (void)setLogHandler:(SNMLogHandler)logHandler {
  [SNMLogger setLogHandler:logHandler];
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
      NSLog(@"[SNMCrashes] ERROR: Checking for a running debugger via sysctl() "
            @"failed.");
      debuggerIsAttached = false;
    }

    if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
      debuggerIsAttached = true;
  });

  return debuggerIsAttached;
}

#pragma mark - private

- (instancetype)init {
  if (self = [super init]) {
    _features = [NSMutableArray new];
    _serverUrl = kSNMDefaultBaseUrl;
    _enabledStateUpdating = NO;
  }
  return self;
}

- (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features {
  if (self.sdkStarted) {
    SNMLogWarning(@"SDK has already been started. You can call `start` only once.");
    return;
  }

  // Validate and set the app secret.
  if ([appSecret length] == 0 || ![[NSUUID alloc] initWithUUIDString:appSecret]) {
    SNMLogError(@"ERROR: AppSecret is invalid");
    return;
  }
  self.appSecret = appSecret;

  // Set backend API version.
  self.apiVersion = kSNMAPIVersion;

  // Init the main pipeline.
  [self initializePipeline];

  // Init requested features.
  for (Class obj in features) {
    id<SNMFeatureInternal> feature = [obj sharedInstance];

    // Set delegate.
    feature.delegate = self;
    [self.features addObject:feature];

    // Set log manager.
    [feature onLogManagerReady:self.logManager];
    [feature startFeature];
  }
  _sdkStarted = YES;

  // If the loglevel hasn't been customized before and we are not running in an app store environment, we set the
  // default loglevel to SNMLogLevelWarning.
  if ((![SNMLogger isUserDefinedLogLevel]) && ([SNMEnvironmentHelper currentAppEnvironment] == SNMEnvironmentOther)) {
    [SNMSonoma setLogLevel:SNMLogLevelWarning];
  }
}

- (void)setServerUrl:(NSString *)serverUrl {
  @synchronized(self) {
    _serverUrl = serverUrl;
  }
}

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized(self) {
    if ([self canBeUsed] && [self isEnabled] != isEnabled) {
      self.enabledStateUpdating = YES;

      // Propagate enable/disable on all features.
      for (id<SNMFeatureInternal> feature in self.features) {
        [[feature class] setEnabled:isEnabled];
      }

      // Propagate to log manager.
      [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES];

      // Persist the enabled status.
      [kSNMUserDefaults setObject:[NSNumber numberWithBool:isEnabled] forKey:kSNMCoreIsEnabledKey];
      self.enabledStateUpdating = NO;
    }
  }
}

- (BOOL)isEnabled {
  @synchronized(self) {
    if ([self canBeUsed]) {

      /**
       *  Get isEnabled value from persistence.
       * No need to cache the value in a property, user settings already have their cache mechanism.
       */
      NSNumber *isEnabledNumber = [kSNMUserDefaults objectForKey:kSNMCoreIsEnabledKey];

      // Return the persisted value otherwise it's enabled by default.
      return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
    }
    return NO;
  }
}

- (void)initializePipeline {
  // Construct http headers.
  NSDictionary *headers = @{
    kSNMHeaderContentTypeKey : kSNMContentType,
    kSNMHeaderAppSecretKey : _appSecret,
    kSNMHeaderInstallIDKey : [self.installId UUIDString]
  };

  // Construct the query parameters.
  NSDictionary *queryStrings = @{kSNMAPIVersionKey : kSNMAPIVersion};

  SNMHttpSender *sender = [[SNMHttpSender alloc] initWithBaseUrl:self.serverUrl
                                                         headers:headers
                                                    queryStrings:queryStrings
                                                    reachability:[SNM_Reachability reachabilityForInternetConnection]];

  // Construct storage.
  SNMFileStorage *storage = [[SNMFileStorage alloc] init];

  // Construct log manager.
  _logManager = [[SNMLogManagerDefault alloc] initWithSender:sender storage:storage];

  // Hookup to application life-cycle events
  [kSNMNotificationCenter removeObserver:self];
  [kSNMNotificationCenter addObserver:self
                             selector:@selector(applicationDidEnterBackground)
                                 name:UIApplicationDidEnterBackgroundNotification
                               object:nil];
  [kSNMNotificationCenter addObserver:self
                             selector:@selector(applicationWillEnterForeground)
                                 name:UIApplicationWillEnterForegroundNotification
                               object:nil];
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
      NSString *savedInstallId = [kSNMUserDefaults objectForKey:kSNMInstallIdKey];
      if (savedInstallId) {
        _installId = kSNMUUIDFromString(savedInstallId);
      }

      // Create a new random install Id if persistency failed.
      if (!_installId) {
        _installId = [NSUUID UUID];

        // Persist the install Id string.
        [kSNMUserDefaults setObject:[_installId UUIDString] forKey:kSNMInstallIdKey];
      }
    }
    return _installId;
  }
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = self.sdkStarted;
  if (!canBeUsed) {
    SNMLogError(@"[%@] ERROR: SonomaSDK hasn't been initialized. You need to call [SNMSonoma "
                @"start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.",
                CLASS_NAME_WITHOUT_PREFIX);
  }
  return canBeUsed;
}

#pragma mark - SNMSonomaDelegate

- (void)feature:(id)feature didCreateLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {
  [self.logManager processLog:log withPriority:priority];
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
