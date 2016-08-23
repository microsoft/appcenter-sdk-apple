#import "AVAAvalanchePrivate.h"
#import "AVAFileStorage.h"
#import "AVAHttpSender.h"
#import "AVALogManagerDefault.h"
#import "AVASettings.h"
#import "AVAUtils.h"

// Http Headers + Query string.
static NSString *const kAVAHeaderAppSecretKey = @"App-Secret";
static NSString *const kAVAHeaderInstallIDKey = @"Install-ID";
static NSString *const kAVAContentType = @"application/json";
static NSString *const kAVAContentTypeKey = @"Content-Type";
static NSString *const kAVAAPIVersion = @"1.0.0-preview20160901";
static NSString *const kAVAAPIVersionKey = @"api-version";

// Base URL for HTTP backend API calls.
static NSString *const kAVABaseUrl = @"http://avalanche-perf.westus.cloudapp.azure.com:8081";

@implementation AVAAvalanche

@synthesize installId = _installId;

+ (id)sharedInstance {
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

- (id)init {
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
    id<AVAFeaturePrivate> feature = [obj sharedInstance];

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

  // Set enable/disable on all features.
  for (id<AVAFeaturePrivate> feature in self.features) {
    [feature setEnabled:isEnabled];
  }
  _isEnabled = isEnabled;
}

- (void)initializePipeline {
  // Construct http headers.
  NSDictionary *headers = @{
    kAVAContentTypeKey : kAVAContentType,
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
      NSString *savedInstallId = [kAVASettings objectForKey:kAVAInstallIdKey];
      if (savedInstallId) {
        _installId = kAVAUUIDFromString(savedInstallId);
      }

      // Create a new random install Id if persistency failed.
      if (!_installId) {
        _installId = [NSUUID UUID];

        // Persist the install Id string.
        [kAVASettings setObject:[_installId UUIDString] forKey:kAVAInstallIdKey];
        [kAVASettings synchronize];
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
