/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSMainViewController.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

@interface MSMainViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;
@property (weak, nonatomic) IBOutlet UILabel *installId;
@property (weak, nonatomic) IBOutlet UILabel *appSecret;
@property (weak, nonatomic) IBOutlet UILabel *logUrl;

@end

@implementation MSMainViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSMobileCenter isEnabled];
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

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSMobileCenter setEnabled:sender.on];
  sender.on = [MSMobileCenter isEnabled];
}

@end
