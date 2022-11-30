//
//  MSACDistributeUIUtil.m
//  AppCenterDistribute iOS Framework
//
//  Created by Shadya Barada on 06.12.2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSACDistributeUIUtil.h"
#import "MSACDistribute.h"

#import "MSACBasicMachOParser.h"
#import "MSACDispatcherUtil.h"
#import "MSACDistributeInternal.h"
#import "MSACDistributePrivate.h"

@implementation MSACDistributeUIUtil


+ (ASPresentationAnchor)getPresentationAnchor API_AVAILABLE(ios(13)) {
  UIApplication *application = MSAC_DISPATCH_SELECTOR((UIApplication * (*)(id, SEL)), [UIApplication class], sharedApplication);
  NSSet *scenes = MSAC_DISPATCH_SELECTOR((NSSet * (*)(id, SEL)), application, connectedScenes);
  NSObject *windowScene;
  for (NSObject *scene in scenes) {
    NSInteger activationState = MSAC_DISPATCH_SELECTOR((NSInteger(*)(id, SEL)), scene, activationState);
      if (activationState == 0 && [scene isKindOfClass:[UIWindowScene class]] /*UISceneActivationStateForegroundActive */) {
      windowScene = scene;
    }
  }
  if (!windowScene) {
    MSACLogError([MSACDistribute logTag], @"Could not find an active scene to be used as a presentation anchor");
    return nil;
  }
  NSArray *windows = MSAC_DISPATCH_SELECTOR((NSArray * (*)(id, SEL)), windowScene, windows);
  ASPresentationAnchor anchor = windows.firstObject;
  return anchor;
}


@end

