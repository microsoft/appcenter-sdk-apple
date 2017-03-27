/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsViewController.h"
#import "MobileCenterAnalytics.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"

@interface MSAnalyticsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSAnalytics isEnabled];
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
      [MSAnalytics trackEvent:@"myEvent"];
      break;
    }
    case 1: {
      NSDictionary *properties = @{ @"gender" : @"male", @"age" : @"20", @"title" : @"SDE" };
      [MSAnalytics trackEvent:@"myEvent" withProperties:properties];
      break;
    }
    case 2: {
      [MSAnalytics trackPage:@"myPage"];
      break;
    }

    case 3: {
      NSDictionary *properties = @{ @"gender" : @"female", @"age" : @"28", @"title" : @"PM" };
      [MSAnalytics trackPage:@"myPage" withProperties:properties];
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
