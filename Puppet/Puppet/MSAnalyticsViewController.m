/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsViewController.h"
#import "MSAnalyticsResultViewController.h"
#import "MobileCenterAnalytics.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"

@interface MSAnalyticsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;
@property (nonatomic) NSMutableDictionary<NSString*,NSString*> *properties;
@property (nonatomic) MSAnalyticsResultViewController *analyticsResult;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSAnalytics isEnabled];
  self.properties = [NSMutableDictionary new];
  self.analyticsResult = [self.storyboard instantiateViewControllerWithIdentifier:@"analyticsResult"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch ([indexPath section]) {

  // Actions
  case 0: {
    switch (indexPath.row) {
    case 0: {
      [MSAnalytics trackEvent:@"myEvent" withProperties:self.properties];
      break;
    }
    case 1: {
      [MSAnalytics trackPage:@"myPage" withProperties:self.properties];
      break;
    }
    case 2: {
      [self.properties setValue:[NSString stringWithFormat:@"Property value %d", self.properties.count + 1]
                         forKey:[NSString stringWithFormat:@"Property name %d", self.properties.count + 1]];
      break;
    }
    case 3: {
      [self.properties removeAllObjects];
      break;
    }
    case 4: {
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

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

@end
