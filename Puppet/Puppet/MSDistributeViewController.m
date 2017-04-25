#import "Constants.h"
#import "MSDistributePrivate.h"
#import "MSDistributeViewController.h"
#import "MSReleaseDetails.h"
#import "MobileCenterDistribute.h"

@interface MSDistributeViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *customized;
@property(weak, nonatomic) IBOutlet UISwitch *enabled;

@end

@implementation MSDistributeViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];

  self.customized.on = [[[NSUserDefaults new] objectForKey:kPUPCustomizedUpdateAlertKey] isEqual:@1];
  self.enabled.on = [MSDistribute isEnabled];
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

  // Section with alerts.
  case 0: {
    switch (indexPath.row) {
    case 0: {
      MSReleaseDetails *details = [MSReleaseDetails new];
      details.appName = @"Puppet";
      details.version = @"10";
      details.shortVersion = @"1.0";
      if (self.customized.on) {
        MSDistribute *distribute = [MSDistribute sharedInstance];
        [[distribute delegate] distribute:distribute releaseAvailableWithDetails:details];
      } else {
        [[MSDistribute sharedInstance] showConfirmationAlert:details];
      }
      break;
    }
    case 1:
      [[MSDistribute sharedInstance] showDistributeDisabledAlert];
      break;
    }
  }
  }
}

- (IBAction)customizedSwitchUpdated:(UISwitch *)sender {
  [[NSUserDefaults new] setObject:sender.on ? @1 : @0 forKey:kPUPCustomizedUpdateAlertKey];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSDistribute setEnabled:sender.on];
  sender.on = [MSDistribute isEnabled];
}

@end
