/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

// TODO: The file should be relocated under iOS sub folder once multiple-platforms branch is merged into develop.

#import <UIKit/UIKit.h>

@interface PropertyViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *keyTextField;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

@end
