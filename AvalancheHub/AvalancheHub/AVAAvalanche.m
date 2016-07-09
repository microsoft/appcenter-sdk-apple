#import "AVAAvalanchePrivate.h"
#import "AVAFeaturePrivate.h"
#import "AVAChannelDefault.h"
#import "AVAHttpSender.h"
#import "AVAFileStorage.h"
#import "AVAUtils.h"
#import "AVASettings.h"

static NSString* const kAVABaseUrl = @"http://avalanche-perf.westus.cloudapp.azure.com:8081";
static NSString* const kAVAAPIVersion = @"1.0.0-preview20160901";
static NSString* const kAVAInstallId = @"AVAInstallId";
static NSTimeInterval const kAVASessionTimeOut = 20;


@implementation AVAAvalanche

+ (id)sharedInstance {
  static AVAAvalanche *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)useFeatures:(NSArray<Class> *)features withAppKey:(NSString *)appKey {
  [[self sharedInstance] useFeatures:features withAppKey:appKey];
}

- (void)useFeatures:(NSArray<Class> *)features withAppKey:(NSString *)appKey {
  
  if (self.featuresStarted) {
    AVALogWarning(@"SDK has already been started. You can call `useFeature` only once.");
    return;
  }
  
  if ([appKey length] == 0) {
    AVALogError(@"ERROR: AppId is invalid");
    return;
  }
  
  // Set app ID and UUID
  self.appKey = appKey;
  self.apiVersion = kAVAAPIVersion;
  
  // Set install Id
  [self setInstallId];

  [self initializePipeline];

  for(Class obj in features) {
    id<AVAFeaturePrivate> feature = [obj sharedInstance];
    
    // Set delegate
    feature.delegate = self;
    [self.features addObject:feature];
    [feature startFeature];
  }

  _featuresStarted = YES;
}

- (void)initializePipeline {
  AVAHttpSender *sender = [[AVAHttpSender alloc] initWithBaseUrl:kAVABaseUrl];
  AVAFileStorage *storage = [[AVAFileStorage alloc] init];
  _channel = [[AVAChannelDefault alloc] initWithSender:sender storage:storage];
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

- (NSString*)appKey {
  return _appKey;
}

- (NSUUID*)sid {
  return _sid;
}

- (NSUUID*)installId {
  return _installId;
}

- (NSString*)apiVersion {
  return _apiVersion;
}

- (void)send:(id<AVALog>)log {
  // TODO
  // Use fabs(absolute) since last sent time was in past and the delta is negative.
  if (log.sid == nil || (fabs([self.lastLogSent timeIntervalSinceNow]) >= kAVASessionTimeOut /* && fabs([self.lastActivityPaused timeIntervalSinceNow]) >= kAVASessionTimeOut */)) {
    self.sid = [NSUUID UUID];
  }

  // Set the session id
  log.sid = self.sid;
  [self.channel enqueueItem:log];
  
  // Cache the sent time
  self.lastLogSent = [NSDate date];
}

- (void)setInstallId {
  if (_installId)
    return;

  // Check if install id has already been persisted
  NSString *installIdString = [kAVASettings objectForKey:kAVAInstallId];
  self.installId = [kAVASettings objectForKey:kAVAInstallId];

  // Use the persisted install id
  if ([installIdString length] > 0) {
    self.installId = [[NSUUID alloc] initWithUUIDString:installIdString];
  } else {
    
    // Create a new random install id
    self.installId = [NSUUID UUID];
    
    // Persist the install ID string
    [kAVASettings setObject:[self.installId UUIDString]  forKey:kAVAInstallId];
    [kAVASettings synchronize];
  }
}

@end
