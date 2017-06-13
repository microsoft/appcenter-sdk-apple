/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSPropertiesTableDataSource.h"
#import "PropertyViewCell.h"

@implementation MSPropertiesTableDataSource

- (instancetype) initWithTable:(UITableView *) tableView {
  self.keys = [NSMutableArray new];
  self.values = [NSMutableArray new];
  self.tableView = tableView;
  self.tableView.dataSource = self;
  self.count = 0;
  return self;
}

- (void) addNewProperty {
  [self.keys addObject:[NSString stringWithFormat:@"key%d", self.count]];
  [self.values addObject:[NSString stringWithFormat:@"value%d", self.count++]];
  [self.tableView reloadData];
}

- (void) deleteProperty {
  NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
  if (indexPath) {
    [self.keys removeObjectAtIndex:indexPath.row];
    [self.values removeObjectAtIndex:indexPath.row];
    [self.tableView reloadData];
  }
}

- (void) updateProperties {
  if (self.selectedTextField && [self.selectedTextField isFirstResponder]){
    [self.selectedTextField resignFirstResponder];
  }
}

- (NSDictionary *) properties {
  NSMutableDictionary *properties = [NSMutableDictionary new];
  for (int i = 0; i < self.keys.count; i++) {
    [properties setObject:self.values[i] forKey:self.keys[i]];
  }
  return properties;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  self.selectedTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField.placeholder isEqual: @"Key"]) {
    self.keys[textField.tag] = textField.text;
  } else {
    self.values[textField.tag] = textField.text;
  }
  [self.tableView reloadData];
  self.selectedTextField = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PropertyViewCell *cell = (PropertyViewCell *) [tableView dequeueReusableCellWithIdentifier:@"PropertyViewCell" forIndexPath:indexPath];
  cell.keyTextField.delegate = self;
  cell.valueTextField.delegate = self;
  cell.keyTextField.tag = indexPath.row;
  cell.valueTextField.tag = indexPath.row;
  cell.keyTextField.text = self.keys[indexPath.row];
  cell.valueTextField.text = self.values[indexPath.row];;
  return cell;
}

@end
