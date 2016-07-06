#import "AVAFeaturePrivate.h"
#import "AVAAvalanchePrivate.h"

@implementation AVAFeature

# pragma mark - AVAModule methods

+ (id)sharedInstance {
  [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass",
  NSStringFromSelector(_cmd)];
  return nil;
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
