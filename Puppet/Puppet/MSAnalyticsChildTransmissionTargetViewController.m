/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Constants.h"
#import "MSAnalyticsChildTransmissionTargetViewController.h"

@interface MSAnalyticsChildTransmissionTargetViewController ()

@property(weak, nonatomic) IBOutlet UILabel *childToken1Label;
@property(weak, nonatomic) IBOutlet UILabel *childToken2Label;

@end

@implementation MSAnalyticsChildTransmissionTargetViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.childToken1Label setText:@"Child Target Token 1 - 602c2d52"];
  [self.childToken2Label setText:@"Child Target Token 2 - 902923eb"];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch (indexPath.row) {
  case 0:
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kMSChildTransmissionTargetTokenKey];
    [self.navigationController popViewControllerAnimated:YES];
    break;
  case 1:
    [[NSUserDefaults standardUserDefaults]
        setObject:kMSTargetToken1
           forKey:kMSChildTransmissionTargetTokenKey];
    [self.navigationController popViewControllerAnimated:YES];
    break;
  case 2:
    [[NSUserDefaults standardUserDefaults]
        setObject:kMSTargetToken2
           forKey:kMSChildTransmissionTargetTokenKey];
    [self.navigationController popViewControllerAnimated:YES];
    break;
  default:
    break;
  }
}

@end
