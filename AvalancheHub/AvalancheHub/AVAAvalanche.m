#import "AVAAvalanchePrivate.h"
#import "AVAFeaturePrivate.h"
#import "AVAChannelDefault.h"
#import "AVAHttpSender.h"
#import "AVAFileStorage.h"

static NSString* const kAVABaseUrl = @"https://microsoft.com";

@implementation AVAAvalanche

+ (id)sharedInstance {
  static AVAAvalanche *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)useFeatures:(NSArray<Class> *)features withAppId:(NSString *)appId {
  [[self sharedInstance] useFeatures:features withAppId:appId];
}

- (void)useFeatures:(NSArray<Class> *)features withAppId:(NSString *)appId {
  
  if (self.featuresStarted) {
    AVALogWarning(@"SDK has already been started. You can call `useFeature` only once.");
    return;
  }
  
  if ([appId length] == 0) {
    AVALogError(@"ERROR: AppId is invalid");
    return;
  }
  
  // Set app ID and UUID
  self.appId = appId;
  self.uuid = [[NSUUID UUID] UUIDString];
  self.apiVersion = @"2016-09-01"; // TODO add util funciton
  [self initializePipeline];
  
  for(Class obj in features) {
    id<AVAFeaturePrivate> feature = [obj sharedInstance];
    
    // Set delgate
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

- (NSString*)appId {
  return _appId;
}

- (NSString*)UUID {
  return _uuid;
}

- (NSString*)apiVersion {
  // TODO
  return _apiVersion;
}

- (void)send:(id<AVALog>)log {
  [self.channel enqueueItem:log];
}

- (NSString *)getSessionId {
  return [self UUID];
}

@end
