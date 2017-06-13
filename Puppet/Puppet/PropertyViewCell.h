//
//  PropertyViewCell.h
//  Puppet
//
//  Created by Murat Baysangurov on 09/06/2017.
//  Copyright © 2017 Microsoft Corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PropertyViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *keyTextField;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

@end
