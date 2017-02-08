/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
#import "TodayViewController.h"
@import NotificationCenter;

@interface TodayViewController () <NCWidgetProviding>

@end

static BOOL MobileCenterSDKIsSarted = NO;

@implementation TodayViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  if (!MobileCenterSDKIsSarted) {
    [MSMobileCenter setLogLevel:MSLogLevelVerbose];
    [MSMobileCenter start:@"7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7"
             withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
    MobileCenterSDKIsSarted = YES;
  }
  // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
  // Perform any setup necessary in order to update the view.

  // If an error is encountered, use NCUpdateResultFailed
  // If there's no update required, use NCUpdateResultNoData
  // If there's an update, use NCUpdateResultNewData

  completionHandler(NCUpdateResultNewData);
}

- (IBAction)trackEventClick:(id)sender {
  [MSAnalytics trackEvent:@"test"];
}

- (IBAction)crashClick:(id)sender {

  /* Trigger a crash */
  NSArray *array = [NSArray array];
  [array objectAtIndex:23];
}

@end
