/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSMainViewController.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"

@interface MSMainViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *enabled;
@property(weak, nonatomic) IBOutlet UISwitch *oneCollectorEnabled;
@property(weak, nonatomic) IBOutlet UILabel *installId;
@property(weak, nonatomic) IBOutlet UILabel *appSecret;
@property(weak, nonatomic) IBOutlet UILabel *logUrl;
@property(weak, nonatomic) IBOutlet UILabel *sdkVersion;

@end

@implementation MSMainViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.enabled.on = [MSAppCenter isEnabled];
  self.oneCollectorEnabled.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"isOneCollectorEnabled"];
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

- (IBAction)enableOneCollectorSwitchUpdated:(UISwitch *)sender {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Restart"
                                                                 message:@"Please restart the app for the change to
                                                                         @"take effect."
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  UIAlertAction *exitAction = [UIAlertAction
      actionWithTitle:@"Exit"
                style:UIAlertActionStyleDestructive
              handler:^(UIAlertAction *action) {
                [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"isOneCollectorEnabled"];
                exit(0);
              }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
                                                         sender.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"isOneCollectorEnabled"];
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
  [alert addAction:exitAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
