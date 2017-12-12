/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSPushViewController.h"
#import "AppCenterPush.h"

@interface MSPushViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;

@end

@implementation MSPushViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.enabled.on = [MSPush isEnabled];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSPush setEnabled:sender.on];
  sender.on = [MSPush isEnabled];
}

@end
