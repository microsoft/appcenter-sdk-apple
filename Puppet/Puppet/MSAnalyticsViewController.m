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

static const NSInteger kPropertyIndentationLevel = 0;
static const NSInteger kDefaultIndentationLevel = 0;
static const NSInteger kEventPropertiesSection = 2;
static const NSInteger kTargetPropertiesSection = 3;

typedef NS_ENUM(short, MSPropertyType) {
  MSPropertyTypeArgumentKey,
  MSPropertyTypeArgumentValue,
  MSPropertyTypeTargetKey,
  MSPropertyTypeTargetValue
};

@interface UITextField (MSProperty)
@property(nonatomic, copy) NSString *associatedKey;
@property(nonatomic) MSPropertyType propertyType;
@end

@implementation UITextField (MSProperty)
@dynamic propertyType;
@dynamic associatedKey;
@end

@interface MSAnalyticsViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *enabled;
@property(weak, nonatomic) IBOutlet UISwitch *oneCollectorEnabled;
@property(weak, nonatomic) IBOutlet UITextField *eventName;
@property(weak, nonatomic) IBOutlet UITextField *pageName;
@property(nonatomic) MSAnalyticsResultViewController *analyticsResult;
@property(nonatomic) NSInteger propertiesCount;
@property(weak, nonatomic) IBOutlet UILabel *selectedChildTargetTokenLabel;
@property(nonatomic) MSAnalyticsTranmissionTargetSelectorViewCell *transmissionTargetSelectorCell;
@property(nonatomic) NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, NSString*>*> *targetProperties;
@property(nonatomic) NSMutableDictionary<NSString*, NSString*> *eventProperties;
@property(nonatomic) short propertyCounter;

@end

@implementation MSAnalyticsViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.propertyCounter = 0;
  self.targetProperties = [NSMutableDictionary new];
  self.eventProperties = [NSMutableDictionary new];
  self.transmissionTargetSelectorCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MSAnalyticsTranmissionTargetSelectorViewCell class]) owner:self options:nil] firstObject];
  for (NSString *targetName in self.transmissionTargetSelectorCell.transmissionTargetMapping) {
    self.targetProperties[targetName] = [NSMutableDictionary new];
  }
  __weak __typeof__(self) weakSelf = self;
  self.transmissionTargetSelectorCell.didSelectTransmissionTarget = ^(){
    __typeof__(self) strongSelf = weakSelf;
    [strongSelf.tableView reloadData];
  };
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
  [MSAnalytics trackEvent:self.eventName.text withProperties:self.eventProperties];
  if (self.oneCollectorEnabled.on) {
    MSAnalyticsTransmissionTarget *target = [MSAnalytics
        transmissionTargetForToken: kMSRuntimeTargetToken];
    NSString *childTargetToken =
        [[NSUserDefaults standardUserDefaults] objectForKey:kMSChildTransmissionTargetTokenKey];
    if (childTargetToken) {
      target = [target transmissionTargetForToken:childTargetToken];
    }
    [target trackEvent:self.eventName.text withProperties:self.eventProperties];
  }
}

- (IBAction)trackPage {
  [MSAnalytics trackPage:self.pageName.text withProperties:self.eventProperties];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSAnalytics setEnabled:sender.on];
  sender.on = [MSAnalytics isEnabled];
}

- (NSDictionary *)targetProperties {
  NSMutableDictionary *properties = [NSMutableDictionary new];
  for (int i = 0; i < self.propertiesCount; i++) {
    MSAnalyticsPropertyTableViewCell *cell =
        [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:kTargetPropertiesSection]];
    if (cell) {
      [properties setObject:cell.valueField.text forKey:cell.keyField.text];
    }
  }
  return properties;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isTargetPropertiesRowSection:indexPath.section]) {
    NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
    id target = [MSAnalytics transmissionTargetForToken: selectedTarget];
    NSString *propertyKey, *propertyValue;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
      // Deleting a property.
      
      // Get the key name from the cell.
      NSString *propertyKey = ((MSAnalyticsPropertyTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).keyField.text;
      
      // Remove it everywhere.
      [target removeEventPropertyforKey:propertyKey];
      [self.targetProperties[selectedTarget] removeObjectForKey:selectedTarget];
      [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
      // Adding a property.
      
      // Set the property to default values.
      [self setNewDefaultKey:&propertyKey andValue:&propertyValue];
      
      // Add it everywhere.
      [self.targetProperties[selectedTarget] setObject:propertyValue forKey:propertyKey];
      [target setEventPropertyString:propertyValue forKey:propertyKey];
      [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
  } else if ([self isEventPropertiesRowSection: indexPath.section]) {
    NSString *propertyKey, *propertyValue;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
      NSString *propertyKey = ((MSAnalyticsPropertyTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).keyField.text;
      [self.eventProperties removeObjectForKey:propertyKey];
      [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
      [self setNewDefaultKey:&propertyKey andValue:&propertyValue];
      self.eventProperties[propertyKey] = propertyValue;
      [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
  }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
  if ([self isInsertRowAtIndexPath:indexPath]) {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Add Property";
    return cell;
  } else if ([self isTargetSelectionRowAtIndexPath:indexPath]) {
    return self.transmissionTargetSelectorCell;
  } else if ([self isTargetPropertiesRowSection:indexPath.section]) {
    MSAnalyticsPropertyTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed: NSStringFromClass([MSAnalyticsPropertyTableViewCell class]) owner:self options:nil] firstObject];
    NSString *selectedTarget = self.transmissionTargetSelectorCell.selectedTransmissionTarget;
    cell.keyField.propertyType = MSPropertyTypeTargetKey;
    cell.keyField.text = self.targetProperties[selectedTarget].allKeys[indexPath.row - 2];
    cell.keyField.propertyType = MSPropertyTypeTargetValue;
    cell.valueField.text = self.targetProperties[selectedTarget][cell.keyField.text];
    
    // Remember this initial key for next text update.
    cell.keyField.associatedKey = cell.keyField.text;
    cell.valueField.associatedKey = cell.keyField.text;
    
    // Subscribe for text update.
    [cell.keyField addTarget:self action:@selector(textFieldEditingDidChange:) forControlEvents:UIControlEventEditingChanged];
    return cell;
  } else if ([self isEventPropertiesRowSection:indexPath.section]) {
    MSAnalyticsPropertyTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed: NSStringFromClass([MSAnalyticsPropertyTableViewCell class]) owner:self options:nil] firstObject];
    cell.keyField.propertyType = MSPropertyTypeArgumentKey;
    cell.keyField.text = self.eventProperties.allKeys[indexPath.row - 1];
    cell.keyField.propertyType = MSPropertyTypeArgumentValue;
    cell.valueField.text = self.eventProperties[cell.keyField.text];
    
    // Remember this initial key for next text update.
    cell.keyField.associatedKey = cell.keyField.text;
    cell.valueField.associatedKey = cell.keyField.text;
    
    // Subscribe for text update.
    [cell.keyField addTarget:self action:@selector(textFieldEditingDidChange:) forControlEvents:UIControlEventEditingChanged];
    return cell;
  } else {
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
  }
}

-(NSUInteger) targetPropertyCount{
  return self.targetProperties[[self.transmissionTargetSelectorCell selectedTransmissionTarget]].count;
}

-(BOOL) isTargetSelectionRowAtIndexPath: (NSIndexPath *)indexPath {
  return indexPath.section == kTargetPropertiesSection && indexPath.row == 0;
}

- (BOOL)isInsertRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.section == kEventPropertiesSection &&
         indexPath.row == 0)||
  (indexPath.section == kEventPropertiesSection &&
  indexPath.row == 1);
}

- (BOOL)isEventPropertiesRowSection:(NSInteger)section {
  return section == kEventPropertiesSection;
}

- (BOOL)isTargetPropertiesRowSection:(NSInteger) section{
  return section == kTargetPropertiesSection;
}

- (void)textFieldEditingDidChange:(UITextField *)sender{
  NSString *selectedTarget, *currentPropertyKey, *currentPropertyValue;
  MSAnalyticsTransmissionTarget *target;
  switch (sender.propertyType) {
    case MSPropertyTypeTargetKey:
      selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
      currentPropertyKey = sender.associatedKey;
      sender.associatedKey = sender.text;
      currentPropertyValue = self.targetProperties[selectedTarget][currentPropertyKey];
      target = [MSAnalytics transmissionTargetForToken:selectedTarget];
      [target removeEventPropertyforKey:currentPropertyKey];
      [target setEventPropertyString:currentPropertyValue forKey:sender.text];
      [self.targetProperties[selectedTarget] removeObjectForKey:currentPropertyKey];
      self.targetProperties[selectedTarget][sender.text] = currentPropertyValue;
      break;
    case MSPropertyTypeTargetValue:
      selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
      currentPropertyKey = sender.associatedKey;
      target = [MSAnalytics transmissionTargetForToken:selectedTarget];
      [target setEventPropertyString:sender.text forKey:currentPropertyKey];
      self.targetProperties[selectedTarget][currentPropertyKey] = sender.text;
      break;
    case MSPropertyTypeArgumentKey:
      currentPropertyKey = sender.associatedKey;
      sender.associatedKey = sender.text;
      currentPropertyValue = self.eventProperties[currentPropertyKey];
      [self.eventProperties removeObjectForKey:currentPropertyKey];
      self.eventProperties[sender.text] = currentPropertyValue;
      break;
    case MSPropertyTypeArgumentValue:
      currentPropertyKey = sender.associatedKey;
      self.eventProperties[currentPropertyKey] = sender.text;
      break;
    default:
      break;
  }
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isInsertRowAtIndexPath:indexPath]) {
    return UITableViewCellEditingStyleInsert;
  } else if ([self isTargetSelectionRowAtIndexPath:indexPath]){
    return UITableViewCellEditingStyleNone;
  }else {
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
  if ([self isTargetPropertiesRowSection:section]) {
    return [self targetPropertyCount] + 2;
  } else if ([self isTargetPropertiesRowSection:section]) {
    return [self targetPropertyCount] + 1;
  } else {
    return [super tableView:tableView numberOfRowsInSection:section];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isEventPropertiesRowSection:indexPath.section] || [self isTargetPropertiesRowSection:indexPath.section]) {
    return
        [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
  } else {
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
  }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (([self isTargetPropertiesRowSection:indexPath.section] && ![self isTargetSelectionRowAtIndexPath:indexPath]) || [self isEventPropertiesRowSection:indexPath.section]) {
    return kPropertyIndentationLevel;
  } else {
    return kDefaultIndentationLevel;
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self isEventPropertiesRowSection:indexPath.section] || [self isTargetPropertiesRowSection:indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

-(void)setNewDefaultKey:(NSString**)key andValue:(NSString**)value{
  *key = [NSString stringWithFormat:@"key%d", self.propertyCounter];
  *value = [NSString stringWithFormat:@"value%d", self.propertyCounter];
  self.propertyCounter++;
}

@end
