/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSMainViewController.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"

@interface MSMainViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;
@property (weak, nonatomic) IBOutlet UILabel *installId;
@property (weak, nonatomic) IBOutlet UILabel *appSecret;
@property (weak, nonatomic) IBOutlet UILabel *logUrl;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersion;

@end

@implementation MSMainViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSAppCenter isEnabled];
  self.installId.text = [[MSAppCenter installId] UUIDString];
  self.appSecret.text = [[MSAppCenter sharedInstance] appSecret];
  self.logUrl.text = [[MSAppCenter sharedInstance] logUrl];
  self.sdkVersion.text = [MSAppCenter sdkVersion];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAppCenter setEnabled:sender.on];
  sender.on = [MSAppCenter isEnabled];
}

@end
