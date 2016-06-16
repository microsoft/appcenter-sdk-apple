//
//  AVACore.m
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import "AVACorePrivate.h"
#import "AVAFeaturePrivate.h"

@implementation AVACore

+ (id)sharedInstance {
  static AVACore *sharedInstance = nil;
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
    // LOG: Method can only be called once
    return;
  }
  
  for (Class featureClass in features) {
    AVAFeature *feature = [featureClass sharedInstance];
      
    if (!feature.identifier) {
      feature.identifier = identifier;
    }
    [self.features addObject:feature];
    [feature startFeature];
  }
  
  _featuresStarted = YES;
}

@end
