/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface MSPropertiesTableDataSource : NSObject <UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) UITextField *selectedTextField;
@property (nonatomic) NSMutableArray<NSString*> *keys;
@property (nonatomic) NSMutableArray<NSString*> *values;

- (instancetype) initWithTable:(UITableView *) tableView;
- (void) addNewProperty;
- (void) deleteProperty;
- (void) updateProperties;
- (NSDictionary*) properties;

@end
