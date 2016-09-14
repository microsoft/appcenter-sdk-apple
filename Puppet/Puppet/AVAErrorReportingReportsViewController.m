#import "AVAErrorReportingReportsViewController.h"
#import "SNMCrashes.h"

@interface AVAErrorReportingReportsViewController ()

@end

@implementation AVAErrorReportingReportsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Crashes";
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
  [SNMCrashes generateTestCrash];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 3;
  } else {
    return 3;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return NSLocalizedString(@"Test Crashes", @"");
  } else {
    return NSLocalizedString(@"Alerts", @"");
  }
  return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if (section == 1) {
    return NSLocalizedString(@"Presented UI relevant for localization", @"");
  }

  return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  // Configure the cell...
  if (indexPath.section == 0) {
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
    default:
      break;
    }
  } else {
    if (indexPath.row == 0) {
      cell.textLabel.text = NSLocalizedString(@"Anonymous", @"");
    } else if (indexPath.row == 1) {
      cell.textLabel.text = NSLocalizedString(@"Anonymous 3 buttons", @"");
    } else {
      cell.textLabel.text = NSLocalizedString(@"Non-anonymous", @"");
    }
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
    default:
      break;
    }
  }
}

@end
