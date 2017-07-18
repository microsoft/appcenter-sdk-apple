#import "MSWrapperCrashesHelper.h"

@interface MSWrapperCrashesHelper ()
@property(weak, nonatomic) id<MSCrashHandlerSetupDelegate> crashHandlerSetupDelegate;
@end

@implementation MSWrapperCrashesHelper

+ (instancetype)sharedInstance {
  static MSWrapperCrashesHelper *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void) setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate {
  [[self sharedInstance] setCrashHandlerSetupDelegate:delegate];
}

+ (id<MSCrashHandlerSetupDelegate>) getCrashHandlerSetupDelegate {
  return [[self sharedInstance] crashHandlerSetupDelegate];
}

@end
