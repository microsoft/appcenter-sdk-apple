#import "MSDistributeViewController.h"
#import "MobileCenterDistribute.h"
#import "MSDistributePrivate.h"

@implementation MSDistributeViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Distribute";
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

  // Settings
  case 0: {
    return 1;
  }
  case 1: {
    return 2;
  }
  default:
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
  case 0: {
    return @"Settings";
  }
  case 1: {
    return @"Alerts";
  }
  default:
    return 0;
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier;
  UITableViewCell *cell;
  switch ([indexPath section]) {

  // Enable/diable-cell section.
  case 0: {
    CellIdentifier = @"EnabledCell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    switch (indexPath.row) {
    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Set Enabled", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;

      // Define the switch control and add it to the cell.
      UISwitch *enabledSwitch = [[UISwitch alloc] init];
      enabledSwitch.on = [MSDistribute isEnabled];
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

  // Alerts section.
  case 1: {
    CellIdentifier = @"AlertCell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    switch (indexPath.row) {
    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Show Update Alert", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;
      break;
    }
    case 1: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Show Disabled Alert", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;
      break;
    }
    default: { break; }
    }
  }

  // Default Section just in case.
  default:
    CellIdentifier = @"Default";
    break;
  }

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch ([indexPath section]) {

  // Settings
  case 0: {
    switch (indexPath.row) {
    default:
      break;
    }
    break;
  }

  // Section with alerts.
  case 1: {
    switch (indexPath.row) {
    case 0:
      [[MSDistribute sharedInstance] showConfirmationAlert:nil];
      break;
    case 1:
      [[MSDistribute sharedInstance] showDistributeDisabledAlert];
      break;
    default:
      break;
    }
  }

  default:
    break;
  }
}

- (void)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSDistribute setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSDistribute isEnabled];
}

@end
