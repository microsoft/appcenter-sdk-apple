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

- (void)startFeature {
  AVALogVerbose(@"AVAFeature: Feature started");
}

+ (void)enable {
  
}

+ (void)disable {
  
}

+ (BOOL)isEnabled {
  return YES;
}

@end
