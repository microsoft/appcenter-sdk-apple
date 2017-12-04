/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCustomPropertyTableViewCell.h"

@interface MSCustomPropertyTableViewCell () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic) UIPickerView *typePickerView;
@property (nonatomic) UIDatePicker *datePickerView;

@end

@implementation MSCustomPropertyTableViewCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  self.typeTextField.delegate = self;
  self.typeTextField.text = MSCustomPropertyTableViewCell.types[0];
  self.typeTextField.tintColor = [UIColor clearColor];
  
  [self pickerView:self.typePickerView didSelectRow:0 inComponent:0];
}

- (void)showTypePicker {
  self.typePickerView = [[UIPickerView alloc] init];
  self.typePickerView.backgroundColor = [UIColor whiteColor];
  self.typePickerView.showsSelectionIndicator = YES;
  self.typePickerView.dataSource = self;
  self.typePickerView.delegate = self;
  
  // Select current type.
  [self.typePickerView selectRow:[MSCustomPropertyTableViewCell.types indexOfObject:self.typeTextField.text] inComponent:0 animated:NO];
  
  UIToolbar *toolbar = [self toolBarForPicker];
  self.typeTextField.inputView = self.typePickerView;
  self.typeTextField.inputAccessoryView = toolbar;
}

- (void)showDatePicker {
  self.datePickerView = [[UIDatePicker alloc] init];
  self.datePickerView.backgroundColor = [UIColor whiteColor];
  self.datePickerView.datePickerMode = UIDatePickerModeDateAndTime;
  self.datePickerView.date = [NSDate date];
  
  // Update label.
  [self.datePickerView addTarget:self action:@selector(datePickerChanged) forControlEvents:UIControlEventValueChanged];
  [self datePickerChanged];
  
  UIToolbar *toolbar = [self toolBarForPicker];
  self.valueTextField.inputView = self.datePickerView;
  self.valueTextField.inputAccessoryView = toolbar;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  if (textField == self.typeTextField) {
    [self showTypePicker];
    return YES;
  } else if (textField == self.valueTextField) {
    return YES;
  }
  return NO;
}

- (UIToolbar *)toolBarForPicker {
  UIToolbar *toolbar = [[UIToolbar alloc] init];
  [toolbar sizeToFit];
  UIBarButtonItem *flexibleSpace =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *doneButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneClicked)];
  [toolbar setItems:@[flexibleSpace, doneButton]];
  return toolbar;
}

- (void)doneClicked {
  [self.typeTextField resignFirstResponder];
  [self.valueTextField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  return NO;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return MSCustomPropertyTableViewCell.types.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return MSCustomPropertyTableViewCell.types[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  self.typeTextField.text = MSCustomPropertyTableViewCell.types[row];
  
  // Reset to default values.
  self.valueTextField.text = @"";
  self.valueTextField.keyboardType = UIKeyboardTypeDefault;
  self.valueTextField.tintColor = self.keyTextField.tintColor;
  self.valueTextField.delegate = nil;
  self.valueTextField.inputView = nil;
  self.valueTextField.inputAccessoryView = nil;
  
  switch (row) {

    // Clear.
    case 0:
      self.valueBottomConstraint.active = NO;
      self.valueLabel.hidden = YES;
      self.valueTextField.hidden = YES;
      self.boolValue.hidden = YES;
      break;

    // String.
    case 1:
      self.valueBottomConstraint.active = YES;
      self.valueLabel.hidden = NO;
      self.valueTextField.hidden = NO;
      self.valueTextField.keyboardType = UIKeyboardTypeASCIICapable;
      self.boolValue.hidden = YES;
      break;
      
    // Number.
    case 2:
      self.valueBottomConstraint.active = YES;
      self.valueLabel.hidden = NO;
      self.valueTextField.hidden = NO;
      self.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
      self.boolValue.hidden = YES;
      break;
      
    // Boolean.
    case 3:
      self.valueBottomConstraint.active = YES;
      self.valueLabel.hidden = NO;
      self.valueTextField.hidden = YES;
      self.boolValue.hidden = NO;
      break;
      
    // DateTime.
    case 4:
      self.valueBottomConstraint.active = YES;
      self.valueLabel.hidden = NO;
      self.valueTextField.hidden = NO;
      self.valueTextField.tintColor = [UIColor clearColor];
      self.valueTextField.delegate = self;
      self.boolValue.hidden = YES;
      [self showDatePicker];
      break;
  }
  
  // Apply constraints.
  [self.contentView layoutIfNeeded];
  
  // Animate table.
  UITableView *tableView = self.tableView;
  [tableView beginUpdates];
  [tableView endUpdates];
}

- (void)datePickerChanged {
  static NSDateFormatter *dateFormatter = nil;
  if (!dateFormatter) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
  }
  self.valueTextField.text = [dateFormatter stringFromDate:self.datePickerView.date];
}

- (UITableView *)tableView {
  id view = [self superview];
  while (view && [view isKindOfClass:[UITableView class]] == NO) {
    view = [view superview];
  }
  return (UITableView *)view;
}

+ (NSArray *)types {
  static NSArray *_types;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _types = @[ @"Clear", @"String", @"Number", @"Boolean", @"DateTime" ];
  });
  return _types;
}

@end
