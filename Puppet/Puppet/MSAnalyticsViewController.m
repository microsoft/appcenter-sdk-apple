/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AppCenterAnalytics.h"
#import "MSAnalyticsChildTransmissionTargetViewController.h"
#import "MSAnalyticsViewController.h"
#import "MSAnalyticsPropertyTableViewCell.h"
#import "MSAnalyticsResultViewController.h"
// trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
#import "MSAnalyticsInternal.h"

static NSInteger kPropertiesSection = 3;

@interface MSAnalyticsViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *enabled;
@property(weak, nonatomic) IBOutlet UISwitch *oneCollectorEnabled;
@property(weak, nonatomic) IBOutlet UITextField *eventName;
@property(weak, nonatomic) IBOutlet UITextField *pageName;
@property(nonatomic) MSAnalyticsResultViewController *analyticsResult;
@property(nonatomic) NSInteger propertiesCount;
@property(weak, nonatomic) IBOutlet UILabel *selectedChildTargetTokenLabel;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
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
  if (self.oneCollectorEnabled.on) {
    MSAnalyticsTransmissionTarget *target = [MSAnalytics
        transmissionTargetForToken:@"b9bb5bcb40f24830aa12f681e6462292-10b4c5da-67be-49ce-936b-8b2b80a83a80-7868"];
    NSString *childTargetToken =
        [[NSUserDefaults standardUserDefaults] objectForKey:kMSChildTransmissionTargetTokenKey];
    if (childTargetToken) {
      target = [target transmissionTargetForToken:childTargetToken];
    }
    [target trackEvent:self.eventName.text withProperties:self.properties];
  } else {
    [MSAnalytics trackEvent:self.eventName.text withProperties:self.properties];
  }
}

- (IBAction)trackPage {
  [MSAnalytics trackPage:self.pageName.text withProperties:self.properties];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

- (NSDictionary *)properties {
  NSMutableDictionary *properties = [NSMutableDictionary new];
  for (int i = 0; i < self.propertiesCount; i++) {
    MSAnalyticsPropertyTableViewCell *cell =
        [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:kPropertiesSection]];
    if (cell) {
      [properties setObject:cell.valueField.text forKey:cell.keyField.text];
    }
  }
  return properties;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    self.propertiesCount--;
    [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
  } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    self.propertiesCount++;
    [tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if ([self isPropertiesRowSection:section]) {
    return self.propertiesCount + 1;
  } else {
    return [super tableView:tableView numberOfRowsInSection:section];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isPropertiesRowSection:indexPath.section]) {
    return
        [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
  } else {
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
  }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isPropertiesRowSection:indexPath.section]) {
    return [super tableView:tableView
        indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
  } else {
    return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self isPropertiesRowSection:indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isInsertRowAtIndexPath:indexPath]) {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Add Property";
    return cell;
  } else if ([self isPropertiesRowSection:indexPath.section]) {
    return
        [[[NSBundle mainBundle] loadNibNamed:@"MSAnalyticsPropertyTableViewCell" owner:self options:nil] firstObject];
  } else {
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
  }
}

@end
