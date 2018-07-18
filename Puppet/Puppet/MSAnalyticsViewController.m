/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AppCenterAnalytics.h"
#import "Constants.h"
#import "MSAnalyticsChildTransmissionTargetViewController.h"
#import "MSAnalyticsViewController.h"
#import "MSAnalyticsPropertyTableViewCell.h"
#import "MSAnalyticsResultViewController.h"
#import "MSAnalyticsTranmissionTargetSelectorViewCell.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"
#import "MSEventPropertiesTableSection.h"
#import "MSTargetPropertiesTableSection.h"

static const NSInteger kEventPropertiesSection = 2;
static const NSInteger kTargetPropertiesSection = 3;

@interface MSAnalyticsViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *enabled;
@property(weak, nonatomic) IBOutlet UISwitch *oneCollectorEnabled;
@property(weak, nonatomic) IBOutlet UITextField *eventName;
@property(weak, nonatomic) IBOutlet UITextField *pageName;
@property(nonatomic) MSAnalyticsResultViewController *analyticsResult;
@property(weak, nonatomic) IBOutlet UILabel *selectedChildTargetTokenLabel;
@property(nonatomic) MSEventPropertiesTableSection *eventPropertiesSection;
@property(nonatomic) MSTargetPropertiesTableSection *targetPropertiesSection;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.targetPropertiesSection =
      [[MSTargetPropertiesTableSection alloc] initWithTableSection:kTargetPropertiesSection tableView:self.tableView];
  self.eventPropertiesSection =
      [[MSEventPropertiesTableSection alloc] initWithTableSection:kEventPropertiesSection tableView:self.tableView];
  [self.tableView setEditing:YES animated:NO];
  self.enabled.on = [MSAnalytics isEnabled];
  self.analyticsResult = [self.storyboard instantiateViewControllerWithIdentifier:@"analyticsResult"];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSString *childTargetToken = [[NSUserDefaults standardUserDefaults] objectForKey:kMSChildTransmissionTargetTokenKey];
  if (childTargetToken) {
    childTargetToken = [childTargetToken substringToIndex:8];
  } else {
    childTargetToken = @"None";
  }
  [self.selectedChildTargetTokenLabel setText:[NSString stringWithFormat:@"Child Target: %@", childTargetToken]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

- (IBAction)trackEvent {
  NSString *name = self.eventName.text;
  if (!name) {
    return;
  }
  NSDictionary *eventPropertiesDictionary = self.eventPropertiesSection.properties;
  [MSAnalytics trackEvent:name withProperties:eventPropertiesDictionary];
  if (self.oneCollectorEnabled.on) {
    MSAnalyticsTransmissionTarget *target = self.targetPropertiesSection.transmissionTargets[kMSRuntimeTargetToken];
    NSString *childTargetToken =
        [[NSUserDefaults standardUserDefaults] objectForKey:kMSChildTransmissionTargetTokenKey];
    if (childTargetToken) {
      target = self.targetPropertiesSection.transmissionTargets[childTargetToken];
    }
    [target trackEvent:name withProperties:eventPropertiesDictionary];
  }
}

- (IBAction)trackPage {
  [MSAnalytics trackPage:self.pageName.text];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  MSPropertiesTableSection *propertySection = [self propertySectionAtIndexPath:indexPath];
  [propertySection tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}

- (BOOL)isTargetSelectionRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath.section == kTargetPropertiesSection && indexPath.row == 0;
}

- (BOOL)isInsertRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.section == kEventPropertiesSection && indexPath.row == 0) ||
         (indexPath.section == kTargetPropertiesSection && indexPath.row == 1);
}

- (BOOL)isEventPropertiesRowSection:(NSInteger)section {
  return section == kEventPropertiesSection;
}

- (BOOL)isTargetPropertiesRowSection:(NSInteger)section {
  return section == kTargetPropertiesSection;
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  MSPropertiesTableSection *propertySection = [self propertySectionAtIndexPath:indexPath];
  if (propertySection) {
    return [propertySection tableView:tableView editingStyleForRowAtIndexPath:indexPath];
  } else {
    return UITableViewCellEditingStyleDelete;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  MSPropertiesTableSection *propertySection = [self propertySectionAtIndexPath:indexPath];
  if ([propertySection isInsertRowAtIndexPath:indexPath]) {
    [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
  }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  MSPropertiesTableSection *propertySection =
      [self propertySectionAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
  if (propertySection) {
    return [propertySection tableView:tableView numberOfRowsInSection:section];
  }
  return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self propertySectionAtIndexPath:indexPath]) {
    return
        [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
  }
  return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

/**
 * Without this override, the default implementation will try to get a table cell that is out of bounds
 * (since they are inserted/removed at a slightly different time than the actual data source is updated).
 */
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  MSPropertiesTableSection *propertySection = [self propertySectionAtIndexPath:indexPath];
  if (propertySection) {
    return [propertySection tableView:tableView cellForRowAtIndexPath:indexPath];
  }
  return [self isEventPropertiesRowSection:indexPath.section] || [self isTargetPropertiesRowSection:indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  MSPropertiesTableSection *propertySection = [self propertySectionAtIndexPath:indexPath];
  if (propertySection) {
    return [propertySection tableView:tableView cellForRowAtIndexPath:indexPath];
  }
  return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (MSPropertiesTableSection *)propertySectionAtIndexPath:(NSIndexPath *)indexPath {
  if ([self.eventPropertiesSection hasSectionId:indexPath.section]) {
    return self.eventPropertiesSection;
  } else if ([self.targetPropertiesSection hasSectionId:indexPath.section]) {
    return self.targetPropertiesSection;
  }
  return nil;
}
@end
