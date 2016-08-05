/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionTrackerHelper.h"
#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>

@implementation AVASessionTrackerHelper

+ (void)simulateDidEnterBackgroundNotification {
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:self];
}

+ (void)simulateWillEnterForegroundNotification {
  // Enter foreground
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];
}

@end
