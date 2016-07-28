#import "AVAAvalanchePrivate.h"
#import "AVAChannelDefault.h"
#import "AVAConstants+Internal.h"
#import "AVADeviceLog.h"
#import "AVAFeaturePrivate.h"
#import "AVAFileStorage.h"
#import "AVAHttpSender.h"
#import "AVALogManagerDefault.h"
#import "AVASettings.h"
#import "AVAStartSessionLog.h"
#import "AVAUtils.h"

// Http Headers + Query string.
static NSString *const kAVAHeaderAppKeyKey = @"App-Key";
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

+ (void)useFeatures:(NSArray<Class> *)features withAppKey:(NSString *)appKey {
  [[self sharedInstance] useFeatures:features withAppKey:appKey];
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

- (void)useFeatures:(NSArray<Class> *)features withAppKey:(NSString *)appKey {
  if (self.featuresStarted) {
    AVALogWarning(@"SDK has already been started. You can call `useFeatures` only once.");
    return;
  }

  // Validate and set the app key.
  if ([appKey length] == 0 || ![[NSUUID alloc] initWithUUIDString:appKey]) {
    AVALogError(@"ERROR: AppKey is invalid");
    return;
  }
  self.appKey = appKey;

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

  // Init device tracker.
  _deviceTracker = [[AVADeviceTracker alloc] init];

  // Init session tracker.
  _sessionTracker = [[AVASessionTracker alloc] init];
  self.sessionTracker.delegate = self;
  [self.sessionTracker start];

  // Construct http headers.
  NSDictionary *headers = @{
    kAVAContentTypeKey : kAVAContentType,
    kAVAHeaderAppKeyKey : _appKey,
    kAVAHeaderInstallIDKey : [self.installId UUIDString]
  };

  // Construct the query parameters.
  NSDictionary *queryStrings = @{kAVAAPIVersionKey : kAVAAPIVersion};
  AVAHttpSender *sender = [[AVAHttpSender alloc] initWithBaseUrl:kAVABaseUrl headers:headers queryStrings:queryStrings];

  // Construct storage.
  AVAFileStorage *storage = [[AVAFileStorage alloc] init];

  // Construct log manager.
  _logManager = [[AVALogManagerDefault alloc] initWithSender:sender storage:storage];
}

- (NSString *)appKey {
  return _appKey;
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

- (void)setCommonLogInfo:(id<AVALog>)log withSessionId:(NSString *)sessionId {

  // Set common log info.
  log.sid = sessionId;
  log.toffset = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
  log.device = self.deviceTracker.device;
}

- (void)sendLog:(id<AVALog>)log withPriority:(AVAPriority)priority {

  // Set last log created time on the session tracker.
  self.sessionTracker.lastCreatedLogTime = [NSDate date];

  // Enqueue log to be sent.
  [self.logManager processLog:log withPriority:AVAPriorityDefault];
}

#pragma mark - AVAAvalancheDelegate

- (void)feature:(id)feature didCreateLog:(id<AVALog>)log withPriority:(AVAPriority)priority {

  // Set common log info and send log.
  [self setCommonLogInfo:log withSessionId:self.sessionTracker.sessionId];
  [self sendLog:log withPriority:AVAPriorityDefault];
}

#pragma mark - AVASessionTrackerDelegate

- (void)sessionTracker:(id)sessionTracker didRenewSessionWithId:(NSString *)sessionId {

  // Refresh device properties.
  [self.deviceTracker refresh];

  // Create a start session log.
  AVAStartSessionLog *log = [[AVAStartSessionLog alloc] init];
  [self setCommonLogInfo:log withSessionId:sessionId];

  // Send log.
  [self sendLog:log withPriority:AVAPriorityDefault];
}

@end
