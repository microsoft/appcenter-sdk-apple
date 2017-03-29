#import "MSDistributeViewController.h"
#import "MobileCenterDistribute.h"
#import "MSDistributePrivate.h"

@interface MSDistributeViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabled;

@end

@implementation MSDistributeViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
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
        case 0:
          [[MSDistribute sharedInstance] showConfirmationAlert:nil];
          break;
        case 1:
          [[MSDistribute sharedInstance] showDistributeDisabledAlert];
          break;
      }
    }
  }
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSDistribute setEnabled:sender.on];
  sender.on = [MSDistribute isEnabled];
}

@end
