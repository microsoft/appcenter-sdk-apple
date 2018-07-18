#import "MSAnalytics.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSAnalyticsTranmissionTargetSelectorViewCell.h"
#import "Constants.h"
#import "MSEventPropertiesTableSection.h"

@interface MSEventPropertiesTableSection ()

@property(nonatomic) NSMutableArray<NSString *> *propertiesKeysByRowIndex;

@end

@implementation MSEventPropertiesTableSection

- (instancetype)init {
  if ((self = [super init])) {
    _properties = [NSMutableDictionary new];
    _propertiesKeysByRowIndex = [NSMutableArray new];
  }
  return self;
}

- (void)propertyKeyChanged:(UITextField *)sender {
  NSInteger arrayIndex = [self cellRowForTextField:sender] - [self propertyCellOffset];
  NSString *newPropertyKey = sender.text;
  NSString *currentPropertyKey = self.propertiesKeysByRowIndex[arrayIndex];
  NSString *currentPropertyValue = self.properties[currentPropertyKey];
  [self.properties removeObjectForKey:currentPropertyKey];
  self.properties[newPropertyKey] = currentPropertyValue;
  self.propertiesKeysByRowIndex[arrayIndex] = newPropertyKey;
}

- (void)propertyValueChanged:(UITextField *)sender {
  NSString *newPropertyValue = sender.text;
  NSInteger arrayIndex = [self cellRowForTextField:sender] - [self propertyCellOffset];
  NSString *currentPropertyKey = self.propertiesKeysByRowIndex[arrayIndex];
  self.properties[currentPropertyKey] = newPropertyValue;
}

- (NSInteger)propertyCount {
  return self.properties.count;
}

- (void)removePropertyAtRow:(NSInteger)row {
  NSInteger arrayIndex = row - [self propertyCellOffset];
  NSString *key = self.propertiesKeysByRowIndex[arrayIndex];
  [self.propertiesKeysByRowIndex removeObject:key];
  [self.properties removeObjectForKey:key];
}

- (void)addPropertyString:(NSString *)property forKey:(NSString *)key {
  self.properties[key] = property;

  // Add the key at the beginning to match the row order.
  self.propertiesKeysByRowIndex = [[@[ key ] arrayByAddingObjectsFromArray:self.propertiesKeysByRowIndex] mutableCopy];
}

- (NSString *)propertyKeyAtRow:(NSInteger)row {
  return self.propertiesKeysByRowIndex[row - [self propertyCellOffset]];
}

- (NSString *)propertyValueForKey:(NSString *)key {
  return self.properties[key];
}

@end
