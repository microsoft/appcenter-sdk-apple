#import "AVAAvalanchePrivate.h"
#import "AVAFeaturePrivate.h"

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
  
  // Set app ID
  self.appId = appId;

  for (Class featureClass in features) {
    AVAFeature *feature = [featureClass sharedInstance];
  
    feature.delegate = self;
    [self.features addObject:feature];
    [feature startFeature];
  }
  
  _featuresStarted = YES;
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

- (NSString*)getAppId {
  return self.appId;
}

- (NSString*)getUUID{
  return [[NSUUID UUID] UUIDString];
}

@end
