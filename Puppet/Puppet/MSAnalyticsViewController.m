/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsViewController.h"
#import "MobileCenterAnalytics.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"
@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Analytics";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  switch (section) {

  // Actions
  case 0: {
    return 4;
  }

  // Settings
  case 1: {
    return 1;
  }
  default:
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
  case 0: {
    return @"Actions";
  }
  case 1: {
    return @"Settings";
  }
  default:
    return 0;
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *CellIdentifier = @"Cell";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  switch ([indexPath section]) {
  case 0: {

    // Configure action cell...
    switch (indexPath.row) {
    case 0: {
      cell.textLabel.text = NSLocalizedString(@"Track Event", @"");
      break;
    }

    case 1: {
      cell.textLabel.text = NSLocalizedString(@"Track Event with Properties", @"");
      break;
    }

    case 2: {
      cell.textLabel.text = NSLocalizedString(@"Track Page", @"");
      break;
    }

    case 3: {
      cell.textLabel.text = NSLocalizedString(@"Track Page with Properties", @"");
      break;
    }

    default:
      break;
    }

    break;
  }
  case 1: {

    // Configure setting cell...
    switch (indexPath.row) {
    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Set Enabled", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;

      // Define the switch control and add it to the cell.
      UISwitch *enabledSwitch = [[UISwitch alloc] init];
      enabledSwitch.on = [MSAnalytics isEnabled];
      CGSize switchSize = [enabledSwitch sizeThatFits:CGSizeZero];
      enabledSwitch.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 10.0f,
                                       (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                                       switchSize.width, switchSize.height);
      enabledSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
      [enabledSwitch addTarget:self
                        action:@selector(enabledSwitchUpdated:)
              forControlEvents:UIControlEventValueChanged];
      [cell.contentView addSubview:enabledSwitch];
      break;
    }

    default:
      break;
    }
    break;
  }

  default:
    break;
  }

  return cell;
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

  // Settings
  case 1: {

    switch (indexPath.row) {
    default:
      break;
    }
    break;
  }

  default:
    break;
  }
}

- (void)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSAnalytics setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSAnalytics isEnabled];
}

@end
