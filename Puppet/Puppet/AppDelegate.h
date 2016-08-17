/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>

#import "AVAErrorReportingDelegate.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, AVAErrorReportingDelegate>

@property(strong, nonatomic) UIWindow *window;

@end
