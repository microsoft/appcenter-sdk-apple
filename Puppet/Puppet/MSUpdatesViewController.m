#import "MSUpdatesViewController.h"
#import "MobileCenterDistribute.h"

@implementation MSUpdatesViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Updates";
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
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  switch (section) {

  // Settings
  case 0: {
    return 1;
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

    // Configure setting cell...
    switch (indexPath.row) {
    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Set Enabled", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;

      // Define the switch control and add it to the cell.
      UISwitch *enabledSwitch = [[UISwitch alloc] init];
      enabledSwitch.on = [MSUpdates isEnabled];
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

  // Settings
  case 0: {

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
  [MSUpdates setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSUpdates isEnabled];
}

@end
