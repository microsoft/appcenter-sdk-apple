/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AppCenter.h"
#import "MSAppCenterPrivate.h"
#import "MSCustomPropertiesViewController.h"
#import "MSCustomPropertyTableViewCell.h"

static NSInteger kPropertiesSection = 0;

@interface MSCustomPropertiesViewController ()

@property (nonatomic) NSInteger propertiesCount;

@end

@implementation MSCustomPropertiesViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.tableView setEditing:YES animated:NO];
}

- (IBAction)send {
  MSCustomProperties *customProperties = [MSCustomProperties new];
  for (int i = 0; i < self.propertiesCount; i++) {
    MSCustomPropertyTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:kPropertiesSection]];
    [cell setPropertyTo:customProperties];
  }
  [MSAppCenter setCustomProperties:customProperties];
  
  // Clear the list
  self.propertiesCount = 0;
  [self.tableView reloadData];
}

- (NSString *)cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellIdentifier = nil;
  if (![self isPropertiesRowSection:indexPath.section]) {
    cellIdentifier = @"send";
  } else if ([self isInsertRowAtIndexPath:indexPath]) {
    cellIdentifier = @"insert";
  } else {
    cellIdentifier = @"customProperty";
  }
  return cellIdentifier;
}

- (BOOL)isInsertRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath.section == kPropertiesSection &&
         indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section] - 1;
}

- (BOOL)isPropertiesRowSection:(NSInteger)section {
  return section == kPropertiesSection;
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isInsertRowAtIndexPath:indexPath]) {
    return UITableViewCellEditingStyleInsert;
  } else {
    return UITableViewCellEditingStyleDelete;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if ([self isInsertRowAtIndexPath:indexPath]) {
     [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if ([self isPropertiesRowSection:section]) {
    return self.propertiesCount + 1;
  } else {
    return 1;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if ([self isPropertiesRowSection:section]) {
    return @"Properties";
  }
  return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self isPropertiesRowSection:indexPath.section];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    self.propertiesCount--;
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    self.propertiesCount++;
    [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellIdentifier = [self cellIdentifierForRowAtIndexPath:indexPath];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
  }
  return cell;
}

@end
