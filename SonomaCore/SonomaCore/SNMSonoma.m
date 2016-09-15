#import "SNMSonomaInternal.h"
#import "SNMFileStorage.h"
#import "SNMHttpSender.h"
#import "SNMLogManagerDefault.h"
#import "SNMUserDefaults.h"
#import "SNMUtils.h"

// Http Headers + Query string.
static NSString *const kSNMHeaderAppSecretKey = @"App-Secret";
static NSString *const kSNMHeaderInstallIDKey = @"Install-ID";
static NSString *const kSNMHeaderContentTypeKey = @"Content-Type";
static NSString *const kSNMContentType = @"application/json";
static NSString *const kSNMAPIVersion = @"1.0.0-preview20160914";
static NSString *const kSNMAPIVersionKey = @"api_version";

// Storage keys
static NSString *const kSNMHubIsEnabledKey = @"kSNMHubIsEnabledKey";

// Base URL for HTTP backend API calls.
static NSString *const kSNMBaseUrl = @"http://in-integration.dev.avalanch.es:8081";

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

#pragma mark - private

- (instancetype)init {
  if (self = [super init]) {
    _features = [NSMutableArray new];
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
}

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized(self) {

    // Force enable/disable on all features.
    for (id<SNMFeatureInternal> feature in self.features) {
      [feature setEnabled:isEnabled];
    }

    // Update the enabled status if needed.
    if ([self isEnabled] != isEnabled) {

      // Persist the enabled status.
      [kSNMUserDefaults setObject:[NSNumber numberWithBool:isEnabled] forKey:kSNMHubIsEnabledKey];
      [kSNMUserDefaults synchronize];
    }
  }
}

- (BOOL)isEnabled {
  @synchronized(self) {
    /**
     *  Get isEnabled value from persistence.
     * No need to cache the value in a property, user settings already have their cache mechanism.
     */
    NSNumber *isEnabledNumber = [kSNMUserDefaults objectForKey:kSNMHubIsEnabledKey];

    // Return the persisted value otherwise it's enabled by default.
    return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
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

  SNMHttpSender *sender = [[SNMHttpSender alloc] initWithBaseUrl:kSNMBaseUrl
                                                         headers:headers
                                                    queryStrings:queryStrings
                                                    reachability:[SNM_Reachability reachabilityForInternetConnection]];

  // Construct storage.
  SNMFileStorage *storage = [[SNMFileStorage alloc] init];

  // Construct log manager.
  _logManager = [[SNMLogManagerDefault alloc] initWithSender:sender storage:storage];
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
        [kSNMUserDefaults synchronize];
      }
    }
    return _installId;
  }
}

#pragma mark - SNMSonomaDelegate

- (void)feature:(id)feature didCreateLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {
  [self.logManager processLog:log withPriority:priority];
}

@end
