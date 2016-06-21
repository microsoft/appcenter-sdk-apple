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

+ (void)useFeatures:(NSArray<Class> *)features {
  [[self sharedInstance] useFeatures:features identifier:nil];
}

+ (void)useFeatures:(NSArray<Class> *)features identifier:(NSString *)identifier {
  [[self sharedInstance] useFeatures:features identifier:identifier];
}

- (void)useFeatures:(NSArray<Class> *)features identifier:(NSString *)identifier {
  
  if (self.featuresStarted) {
    AVALogWarning(@"SDK has already been started. You can call `useFeature` only once.");
    return;
  }
  
  for (Class featureClass in features) {
    AVAFeature *feature = [featureClass sharedInstance];
      
    if (!feature.identifier) {
      feature.identifier = identifier;
    }
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

@end
