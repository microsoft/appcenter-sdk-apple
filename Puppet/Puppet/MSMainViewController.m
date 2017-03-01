/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSMainViewController.h"
#import "MobileCenter.h"

@implementation MSMainViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Puppet App";
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
  // Return the number of sections.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  switch (section) {

  // Actions
  case 0: {
    return 3;
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

  // Actions
  case 0: {
    switch (indexPath.row) {

    case 0: {
      cell.textLabel.text = NSLocalizedString(@"Analytics", @"");
      break;
    }

    case 1: {
      cell.textLabel.text = NSLocalizedString(@"Crashes", @"");
      break;
    }

    case 2: {
      cell.textLabel.text = NSLocalizedString(@"Updates", @"");
      break;
    }

    default:
      break;
    }
    break;
  }

  // Actions
  case 1: {
    switch (indexPath.row) {

    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Set Enabled", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;

      // Define the switch control and add it to the cell.
      UISwitch *enabledSwitch = [[UISwitch alloc] init];
      enabledSwitch.on = [MSMobileCenter isEnabled];
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

  default:
    break;
  }
  }

  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch (indexPath.row) {
  case 0: {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"analytics"];
    [self.navigationController pushViewController:vc animated:YES];
    break;
  }

  case 1: {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"crashes"];
    [self.navigationController pushViewController:vc animated:YES];
    break;
  }

  case 2: {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"updates"];
    [self.navigationController pushViewController:vc animated:YES];
    break;
  }

  default:
    break;
  }
}

- (void)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSMobileCenter setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSMobileCenter isEnabled];
}

@end
