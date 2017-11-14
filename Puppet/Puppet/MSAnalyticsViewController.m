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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  [self.propertiesSource updateProperties];
  switch ([indexPath section]) {

  // Actions
  case 1: {
    switch (indexPath.row) {
    case 0: {
      [MSAnalytics trackEvent:@"myEvent" withProperties:self.propertiesSource.properties];
      break;
    }
    case 1: {
      [MSAnalytics trackPage:@"myPage" withProperties:self.propertiesSource.properties];
      break;
    }
    case 2: {
      [self.navigationController pushViewController:self.analyticsResult animated:true];
      break;
    }
    default:
      break;
    }
    break;
    }
  }
}

@end
