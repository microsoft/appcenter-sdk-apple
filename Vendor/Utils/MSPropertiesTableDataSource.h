/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

// TODO: The file should be relocated under iOS sub folder once multiple-platforms branch is merged into develop.

#import <UIKit/UIKit.h>

@interface MSPropertiesTableDataSource : NSObject <UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) UITextField *selectedTextField;
@property (nonatomic) NSMutableArray<NSString*> *keys;
@property (nonatomic) NSMutableArray<NSString*> *values;
@property (nonatomic) int count;

- (instancetype) initWithTable:(UITableView *) tableView;
- (void) addNewProperty;
- (void) deleteProperty;
- (void) updateProperties;
- (NSDictionary*) properties;

@end
