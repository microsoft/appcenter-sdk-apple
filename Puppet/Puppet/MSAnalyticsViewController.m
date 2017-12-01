/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsViewController.h"
#import "MSAnalyticsResultViewController.h"
#import "AppCenterAnalytics.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"
#import "MSPropertiesTableDataSource.h"

@interface MSAnalyticsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *propertiesTable;
@property (weak, nonatomic) IBOutlet UISwitch *enabled;
@property (weak, nonatomic) IBOutlet UITextField *eventName;
@property (weak, nonatomic) IBOutlet UITextField *pageName;
@property (nonatomic) MSAnalyticsResultViewController *analyticsResult;
@property (nonatomic) MSPropertiesTableDataSource *propertiesSource;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSAnalytics isEnabled];
  self.analyticsResult = [self.storyboard instantiateViewControllerWithIdentifier:@"analyticsResult"];
  self.propertiesSource = [[MSPropertiesTableDataSource alloc] initWithTable:self.propertiesTable];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

- (IBAction)trackEvent {
  [MSAnalytics trackEvent:self.eventName.text withProperties:self.propertiesSource.properties];
}

- (IBAction)trackPage {
  [MSAnalytics trackPage:self.pageName.text withProperties:self.propertiesSource.properties];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

- (IBAction)onAddProperty {
  [self.propertiesSource addNewProperty];
}

- (IBAction)onDeleteProperty {
  [self.propertiesSource deleteProperty];
}

@end
