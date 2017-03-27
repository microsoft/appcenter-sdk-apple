/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashesDetailViewController.h"

@interface MSCrashesDetailViewController ()

@property(strong,nonatomic) IBOutlet UILabel *titleLabel;
@property(strong,nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)doCrash;

@end

@implementation MSCrashesDetailViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.titleLabel.text = self.detailItem.title;
  self.descriptionLabel.text = self.detailItem.desc;
}

- (IBAction)doCrash {
  [self.detailItem crash];
}

@end
