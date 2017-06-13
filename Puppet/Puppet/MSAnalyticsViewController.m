/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsViewController.h"
#import "MSAnalyticsResultViewController.h"
#import "MobileCenterAnalytics.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"
#import "PropertyViewCell.h"

@interface PropertiesTableDataSource : NSObject <UITableViewDataSource, UITextFieldDelegate>

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

@interface MSAnalyticsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *propertiesTable;
@property (weak, nonatomic) IBOutlet UISwitch *enabled;
@property (nonatomic) MSAnalyticsResultViewController *analyticsResult;
@property (nonatomic) PropertiesTableDataSource *propertiesSource;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.enabled.on = [MSAnalytics isEnabled];
  self.analyticsResult = [self.storyboard instantiateViewControllerWithIdentifier:@"analyticsResult"];
  self.propertiesSource = [[PropertiesTableDataSource alloc] initWithTable:self.propertiesTable];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

- (IBAction)onAddProperty {
  [self.propertiesSource addNewProperty];
}

- (IBAction)onDeleteProperty {
  [self.propertiesSource deleteProperty];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  [self.propertiesSource updateProperties];
  switch ([indexPath section]) {

  // Actions
  case 1: {
    switch (indexPath.row) {
    case 0: {
      [MSAnalytics trackEvent:@"myEvent" withProperties:self.propertiesSource.properties];
      break;
    }
    case 1: {
      [MSAnalytics trackPage:@"myPage" withProperties:self.propertiesSource.properties];
      break;
    }
    case 2: {
      [self.navigationController pushViewController:self.analyticsResult animated:true];
      break;
    }
    default:
      break;
    }
    break;
    }
  }
}

@end

@implementation PropertiesTableDataSource

UITextField * selectedTextField;

- (instancetype) initWithTable:(UITableView *) tableView {
  self.keys = [NSMutableArray new];
  self.values = [NSMutableArray new];
  self.tableView = tableView;
  self.tableView.dataSource = self;
  return self;
}

- (void) addNewProperty {
  [self.keys addObject:[NSString stringWithFormat:@"key%lu", (unsigned long)self.keys.count]];
  [self.values addObject:[NSString stringWithFormat:@"value%lu", (unsigned long)self.values.count]];
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
