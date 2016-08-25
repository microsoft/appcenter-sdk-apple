#import "AVAAvalancheInternal.h"
#import "AVAFileStorage.h"
#import "AVAHttpSender.h"
#import "AVALogManagerDefault.h"
#import "AVAUserDefaults.h"
#import "AVAUtils.h"

// Http Headers + Query string.
static NSString *const kAVAHeaderAppSecretKey = @"App-Secret";
static NSString *const kAVAHeaderInstallIDKey = @"Install-ID";
static NSString *const kAVAHeaderContentTypeKey = @"Content-Type";
static NSString *const kAVAContentType = @"application/json";
static NSString *const kAVAAPIVersion = @"1.0.0-preview20160901";
static NSString *const kAVAAPIVersionKey = @"api-version";

// Storage keys
static NSString *const kAVAHubIsEnabledKey = @"kAVAHubIsEnabledKey";

// Base URL for HTTP backend API calls.
static NSString *const kAVABaseUrl = @"http://avalanche-perf.westus.cloudapp.azure.com:8081";

@implementation AVAAvalanche

@synthesize installId = _installId;

+ (instancetype)sharedInstance {
  static AVAAvalanche *sharedInstance = nil;
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

+ (AVALogLevel)logLevel {
  return AVALogger.currentLogLevel;
}

+ (void)setLogLevel:(AVALogLevel)logLevel {
  AVALogger.currentLogLevel = logLevel;
}

+ (void)setLogHandler:(AVALogHandler)logHandler {
  [AVALogger setLogHandler:logHandler];
}

#pragma mark - private

- (instancetype)init {
  if (self = [super init]) {
    _features = [NSMutableArray new];
  }
  return self;
}

- (void)start:(NSString *)appSecret withFeatures:(NSArray<Class> *)features {
  if (self.featuresStarted) {
    AVALogWarning(@"SDK has already been started. You can call `start` only once.");
    return;
  }

  // Validate and set the app secret.
  if ([appSecret length] == 0 || ![[NSUUID alloc] initWithUUIDString:appSecret]) {
    AVALogError(@"ERROR: AppSecret is invalid");
    return;
  }
  self.appSecret = appSecret;

  // Set backend API version.
  self.apiVersion = kAVAAPIVersion;

  // Init the main pipeline.
  [self initializePipeline];

  // Init requested features.
  for (Class obj in features) {
    id<AVAFeatureInternal> feature = [obj sharedInstance];

    // Set delegate.
    feature.delegate = self;
    [self.features addObject:feature];

    // Set log manager.
    [feature onLogManagerReady:self.logManager];
    [feature startFeature];
  }
  _featuresStarted = YES;
}

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized(self) {

    // Force enable/disable on all features.
    for (id<AVAFeatureInternal> feature in self.features) {
      [feature setEnabled:isEnabled];
    }

    // Update the enabled status if needed.
    if ([self isEnabled] != isEnabled) {

      // Persist the enabled status.
      [kAVAUserDefaults setObject:[NSNumber numberWithBool:isEnabled] forKey:kAVAHubIsEnabledKey];
      [kAVAUserDefaults synchronize];
    }
  }
}

- (BOOL)isEnabled {
  @synchronized(self) {
    /**
     *  Get isEnabled value from persistence.
     * No need to cache the value in a property, user settings already have their cache mechanism.
     */
    NSNumber *isEnabledNumber = [kAVAUserDefaults objectForKey:kAVAHubIsEnabledKey];

    // Return the persisted value otherwise it's enabled by default.
    return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
  }
}

- (void)initializePipeline {
  // Construct http headers.
  NSDictionary *headers = @{
    kAVAHeaderContentTypeKey : kAVAContentType,
    kAVAHeaderAppSecretKey : _appSecret,
    kAVAHeaderInstallIDKey : [self.installId UUIDString]
  };

  // Construct the query parameters.
  NSDictionary *queryStrings = @{kAVAAPIVersionKey : kAVAAPIVersion};

  AVAHttpSender *sender = [[AVAHttpSender alloc] initWithBaseUrl:kAVABaseUrl
                                                         headers:headers
                                                    queryStrings:queryStrings
                                                    reachability:[AVA_Reachability reachabilityForInternetConnection]];

  // Construct storage.
  AVAFileStorage *storage = [[AVAFileStorage alloc] init];

  // Construct log manager.
  _logManager = [[AVALogManagerDefault alloc] initWithSender:sender storage:storage];
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
      NSString *savedInstallId = [kAVAUserDefaults objectForKey:kAVAInstallIdKey];
      if (savedInstallId) {
        _installId = kAVAUUIDFromString(savedInstallId);
      }

      // Create a new random install Id if persistency failed.
      if (!_installId) {
        _installId = [NSUUID UUID];

        // Persist the install Id string.
        [kAVAUserDefaults setObject:[_installId UUIDString] forKey:kAVAInstallIdKey];
        [kAVAUserDefaults synchronize];
      }
    }
    return _installId;
  }
}

#pragma mark - AVAAvalancheDelegate

- (void)feature:(id)feature didCreateLog:(id<AVALog>)log withPriority:(AVAPriority)priority {
  [self.logManager processLog:log withPriority:priority];
}

@end
