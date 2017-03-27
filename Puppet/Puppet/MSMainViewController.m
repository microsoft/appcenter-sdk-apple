/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSMainViewController.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

@interface MSMainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *installId;
@property (weak, nonatomic) IBOutlet UILabel *appSecret;
@property (weak, nonatomic) IBOutlet UILabel *logUrl;

@end

@implementation MSMainViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.installId.text = [[MSMobileCenter installId] UUIDString];
  self.appSecret.text = [[MSMobileCenter sharedInstance] appSecret];
  self.logUrl.text = [[MSMobileCenter sharedInstance] logUrl];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

- (IBAction)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSMobileCenter setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSMobileCenter isEnabled];
}

@end
