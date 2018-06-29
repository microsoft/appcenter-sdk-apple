/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

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
        setObject:@"602c2d529a824339bef93a7b9a035e6a-a0189496-cc3a-41c6-9214-b479e5f44912-6819"
           forKey:kMSChildTransmissionTargetTokenKey];
    [self.navigationController popViewControllerAnimated:YES];
    break;
  case 2:
    [[NSUserDefaults standardUserDefaults]
        setObject:@"902923ebd7a34552bd7a0c33207611ab-a48969f4-4823-428f-a88c-eff15e474137-7039"
           forKey:kMSChildTransmissionTargetTokenKey];
    [self.navigationController popViewControllerAnimated:YES];
    break;
  default:
    break;
  }
}

@end
