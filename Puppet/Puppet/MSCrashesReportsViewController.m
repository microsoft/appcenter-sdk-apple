#import "MSCrashes.h"
#import "MSCrashesReportsViewController.h"

#import <CrashLibIOS/CrashLib.h>

@interface MSCrashesReportsViewController ()

@end

@implementation MSCrashesReportsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Crashes";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Private

- (void)triggerSignalCrash {

/* Trigger a crash */
#ifndef __clang_analyzer__
  CFRelease(NULL);
#endif
}

- (void)triggerExceptionCrash {

  /* Trigger a crash */
  NSArray *array = [NSArray array];
  [array objectAtIndex:23];
}

- (void)generateTestCrash {
  [MSCrashes generateTestCrash];
}

- (void)throwObjectiveCException __attribute__((noreturn)) {
    @throw [NSException exceptionWithName:NSGenericException reason:@"An uncaught exception! SCREAM."
                                 userInfo:@{ NSLocalizedDescriptionKey: @"I'm in your program, catching your exceptions!" }];
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
    case 0:
      cell.textLabel.text = NSLocalizedString(@"Signal", @"");
      break;
    case 1:
      cell.textLabel.text = NSLocalizedString(@"Exception", @"");
      break;
    case 2:
      cell.textLabel.text = NSLocalizedString(@"generateTestCrash", @"");
      break;
      case 3:
        cell.textLabel.text = NSLocalizedString(@"Objective-C-Exception", @"");

    default:
      break;
    }
    break;
  }

  // Settings
  case 1: {
    switch (indexPath.row) {
    case 0: {

      // Define the cell title.
      NSString *title = NSLocalizedString(@"Set Enabled", nil);
      cell.textLabel.text = title;
      cell.accessibilityLabel = title;

      // Define the switch control and add it to the cell.
      UISwitch *enabledSwitch = [[UISwitch alloc] init];
      enabledSwitch.on = [MSCrashes isEnabled];
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

  if (indexPath.section == 0) {
    switch (indexPath.row) {
    case 0:
      [self triggerSignalCrash];
      break;
    case 1:
      [self triggerExceptionCrash];
      break;
    case 2:
      [self generateTestCrash];
      break;
      case 3:
        [self throwObjectiveCException];
        break;
    default:
      break;
    }
  }
}

- (void)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSCrashes setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSCrashes isEnabled];
}

@end
