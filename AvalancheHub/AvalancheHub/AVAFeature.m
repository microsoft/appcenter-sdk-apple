#import "AVAFeaturePrivate.h"
#import "AVAAvalanchePrivate.h"

@implementation AVAFeature

# pragma mark - AVAModule methods

+ (id)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)setServerURL:(NSString *)serverURL {
  [[self sharedInstance] setServerURL:serverURL];
}

+ (void)setIdentifier:(NSString *)identifier {
  [[self sharedInstance] setIdentifier:identifier];
}

- (void)startFeature {
  AVALogVerbose(@"AVAFeature: Feature started");
}

+ (void)resume {
  
}

+ (void)stop {
  
}

@end
