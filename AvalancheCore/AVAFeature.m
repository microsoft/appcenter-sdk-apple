//
//  AVAFeature.m
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import "AVAFeaturePrivate.h"
#import "AVAAvalanchePrivate.h"

@implementation AVAFeature

# pragma mark - BITModule methods

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

@end
