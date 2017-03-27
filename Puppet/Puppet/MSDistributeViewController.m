#import "MSDistributeViewController.h"
#import "MobileCenterDistribute.h"

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

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSDistribute setEnabled:sender.on];
  sender.on = [MSDistribute isEnabled];
}

@end
