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
  
  if ([self.appId length] == 0) {
    AVALogError(@"ERROR: AppId is invalid");
    return;
  }
  
  // Set app ID and UUID
  self.appId = appId;
  self.uuid = [[NSUUID UUID] UUIDString];

  [features enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    AVAFeature *feature = [obj sharedInstance];
    
    // Set delgate
    feature.delegate = self;
    [self.features addObject:feature];
    [feature startFeature];
  }];
  
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

- (NSString*)getUUID {
  return self.uuid;
}

- (NSString*)getApiVersion {
  // TODO
  return @"2016-09-01";
}

@end
