#import "MSAnalytics.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSAnalyticsTranmissionTargetSelectorViewCell.h"
#import "Constants.h"
#import "MSTargetPropertiesTableSection.h"

@interface MSTargetPropertiesTableSection ()

@property(nonatomic) MSAnalyticsTranmissionTargetSelectorViewCell *transmissionTargetSelectorCell;
@property(nonatomic)
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *propertiesKeysByRowIndexPerTransmissionTargets;

@end

@implementation MSTargetPropertiesTableSection

- (instancetype)initWithTableSection:(NSInteger)tableSection tableView:(UITableView *)tableView {
  self = [super initWithTableSection:tableSection tableView:tableView];
  if (self) {

    // Set up all transmission targets and associated mappings. The three targets and their tokens are hard coded.
    _transmissionTargets = [NSMutableDictionary new];
    _propertiesPerTransmissionTargets = [NSMutableDictionary new];
    _propertiesKeysByRowIndexPerTransmissionTargets = [NSMutableDictionary new];

    // Parent target.
    MSAnalyticsTransmissionTarget *parentTarget = [MSAnalytics transmissionTargetForToken:kMSRuntimeTargetToken];
    _transmissionTargets[kMSRuntimeTargetToken] = parentTarget;
    _propertiesPerTransmissionTargets[kMSRuntimeTargetToken] = [NSMutableDictionary new];
    _propertiesKeysByRowIndexPerTransmissionTargets[kMSRuntimeTargetToken] = [NSMutableArray new];

    // Child 1 target.
    MSAnalyticsTransmissionTarget *childTarget1 = [parentTarget transmissionTargetForToken:kMSTargetToken1];
    _transmissionTargets[kMSTargetToken1] = childTarget1;
    _propertiesPerTransmissionTargets[kMSTargetToken1] = [NSMutableDictionary new];
    _propertiesKeysByRowIndexPerTransmissionTargets[kMSTargetToken1] = [NSMutableArray new];

    // Child 2 target.
    MSAnalyticsTransmissionTarget *childTarget2 = [parentTarget transmissionTargetForToken:kMSTargetToken2];
    _transmissionTargets[kMSTargetToken2] = childTarget2;
    _propertiesPerTransmissionTargets[kMSTargetToken2] = [NSMutableDictionary new];
    _propertiesKeysByRowIndexPerTransmissionTargets[kMSTargetToken1] = [NSMutableArray new];

    // Reload the tableview when the transmission target selector cell is selcted.
    _transmissionTargetSelectorCell =
        [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MSAnalyticsTranmissionTargetSelectorViewCell class])
                                       owner:self
                                     options:nil] firstObject];
    _transmissionTargetSelectorCell.didSelectTransmissionTarget = ^(void) {
      [tableView reloadData];
    };
  }
  return self;
}

#pragma UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  if ([self isHeaderCellAtIndexPath:indexPath]) {
    return self.transmissionTargetSelectorCell;
  } else {
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
  }
}

#pragma Helper methods

- (NSInteger)numberOfCustomHeaderCells {
  return 1;
}

- (void)propertyKeyChanged:(UITextField *)sender {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  NSInteger arrayIndex = [self cellRowForTextField:sender] - [self propertyCellOffset];
  NSString *currentPropertyKey = self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget][arrayIndex];
  NSString *currentPropertyValue = self.propertiesPerTransmissionTargets[selectedTarget][currentPropertyKey];
  NSString *newPropertyKey = sender.text;
  MSAnalyticsTransmissionTarget *target = self.transmissionTargets[selectedTarget];
  [target removeEventPropertyforKey:currentPropertyKey];
  [target setEventPropertyString:currentPropertyValue forKey:newPropertyKey];
  [self.propertiesPerTransmissionTargets[selectedTarget] removeObjectForKey:currentPropertyKey];
  self.propertiesPerTransmissionTargets[selectedTarget][newPropertyKey] = currentPropertyValue;
  self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget][arrayIndex] = newPropertyKey;
}

- (void)propertyValueChanged:(UITextField *)sender {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  NSInteger arrayIndex = [self cellRowForTextField:sender] - [self propertyCellOffset];
  NSString *currentPropertyKey = self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget][arrayIndex];
  NSString *newPropertyValue = sender.text;
  MSAnalyticsTransmissionTarget *target = self.transmissionTargets[selectedTarget];
  [target setEventPropertyString:newPropertyValue forKey:currentPropertyKey];
  self.propertiesPerTransmissionTargets[selectedTarget][currentPropertyKey] = newPropertyValue;
}

- (BOOL)isHeaderCellAtIndexPath:(NSIndexPath *)indexPath {
  return !([self isPropertyRowAtIndexPath:indexPath] || [self isInsertRowAtIndexPath:indexPath]);
}

- (NSInteger)propertyCount {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  return self.propertiesPerTransmissionTargets[selectedTarget].count;
}

- (void)removePropertyAtRow:(NSInteger)row {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  NSInteger arrayIndex = row - [self propertyCellOffset];
  NSString *key = self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget][arrayIndex];
  MSAnalyticsTransmissionTarget *target = self.transmissionTargets[selectedTarget];
  [target removeEventPropertyforKey:key];
  [self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget] removeObject:key];
  [self.propertiesPerTransmissionTargets[selectedTarget] removeObjectForKey:key];
}

- (void)addPropertyString:(NSString *)property forKey:(NSString *)key {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  self.propertiesPerTransmissionTargets[selectedTarget][key] = property;
  NSMutableArray *orderedPropertiesKeys = orderedPropertiesKeys = [[@[ key ]
      arrayByAddingObjectsFromArray:self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget]] mutableCopy];
  self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget] = orderedPropertiesKeys;
  MSAnalyticsTransmissionTarget *target = self.transmissionTargets[selectedTarget];
  [target setEventPropertyString:property forKey:key];
}

- (NSString *)propertyKeyAtRow:(NSInteger)row {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  NSString *currentPropertyKey =
      self.propertiesKeysByRowIndexPerTransmissionTargets[selectedTarget][row - [self propertyCellOffset]];
  return currentPropertyKey;
}

- (NSString *)propertyValueForKey:(NSString *)key {
  NSString *selectedTarget = [self.transmissionTargetSelectorCell selectedTransmissionTarget];
  return self.propertiesPerTransmissionTargets[selectedTarget][key];
}

@end
