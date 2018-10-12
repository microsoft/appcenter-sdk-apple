#import "AppCenter+Internal.h"
#import "MSAnalytics+Validation.h"
#import "MSBooleanTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventLog.h"
#import "MSEventPropertiesInternal.h"
#import "MSLongTypedProperty.h"
#import "MSPageLog.h"
#import "MSStringTypedProperty.h"

// Events values limitations
static const int kMSMinEventNameLength = 1;
static const int kMSMaxEventNameLength = 256;

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSAnalyticsValidationCategory;

@implementation MSAnalytics (Validation)

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)__unused channelUnit shouldFilterLog:(id<MSLog>)log {
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]]) {
    return ![self validateLog:(MSEventLog *)log];
  } else if ([logObject isKindOfClass:[MSPageLog class]]) {
    return ![self validateLog:(MSPageLog *)log];
  }
  return NO;
}

- (BOOL)validateLog:(MSLogWithNameAndProperties *)log {

  // Validate event name.
  NSString *validName = [self validateEventName:log.name forLogType:log.type];
  if (!validName) {
    return NO;
  }
  log.name = validName;

  // Send only valid properties.
  log.properties = [self validateProperties:log.properties forLogName:log.name andType:log.type];
  return YES;
}

- (nullable NSString *)validateEventName:(NSString *)eventName forLogType:(NSString *)logType {
  if (!eventName || [eventName length] < kMSMinEventNameLength) {
    MSLogError([MSAnalytics logTag], @"%@ name cannot be null or empty", logType);
    return nil;
  }
  if ([eventName length] > kMSMaxEventNameLength) {
    MSLogWarning([MSAnalytics logTag], @"%@ '%@' : name length cannot be longer than %d characters. "
                                       @"Name will be truncated.",
                 logType, eventName, kMSMaxEventNameLength);
    eventName = [eventName substringToIndex:kMSMaxEventNameLength];
  }
  return eventName;
}

- (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                     andType:(NSString *)logType {

  // Keeping this method body in MSAnalytics to use it in unit tests.
  return [MSUtility validateProperties:properties forLogName:logName type:logType];
}

- (MSEventProperties *)validateAppCenterEventProperties:(MSEventProperties *)eventProperties {
  MSEventProperties *validCopy = [MSEventProperties new];
  for (NSString *propertyKey in eventProperties.properties) {
    if ([validCopy.properties count] == kMSMaxPropertiesPerLog) {
      MSLogWarning([MSAnalytics logTag], @"Typed properties cannot contain more than %d items. Skipping other properties.", kMSMaxPropertiesPerLog);
      break;
    }
    MSTypedProperty *property = eventProperties.properties[propertyKey];
    MSTypedProperty *validProperty = [self validateAppCenterTypedProperty:property];
    if (validProperty) {
      validCopy.properties[validProperty.name] = validProperty;
    }
  }
  return validCopy;
}

- (MSTypedProperty *)validateAppCenterTypedProperty:(MSTypedProperty *)typedProperty {
  MSTypedProperty *validProperty;
  if ([typedProperty isKindOfClass:[MSStringTypedProperty class]]) {
    MSStringTypedProperty *originalStringProperty = (MSStringTypedProperty *)typedProperty;
    MSStringTypedProperty *validStringProperty = [MSStringTypedProperty new];
    validStringProperty.value = [self validateAppCenterStringTypedPropertyValue:originalStringProperty.value];
    validProperty = validStringProperty;
  } else if ([typedProperty isKindOfClass:[MSBooleanTypedProperty class]]) {
    validProperty = [MSBooleanTypedProperty new];
    ((MSBooleanTypedProperty *)validProperty).value =  ((MSBooleanTypedProperty *)typedProperty).value;
  } else if ([typedProperty isKindOfClass:[MSLongTypedProperty class]]) {
    validProperty = [MSLongTypedProperty new];
    ((MSLongTypedProperty *)validProperty).value =  ((MSLongTypedProperty *)typedProperty).value;
  } else if ([typedProperty isKindOfClass:[MSDoubleTypedProperty class]]) {
    validProperty = [MSDoubleTypedProperty new];
    ((MSDoubleTypedProperty *)validProperty).value =  ((MSDoubleTypedProperty *)typedProperty).value;
  } else if ([typedProperty isKindOfClass:[MSDateTimeTypedProperty class]]) {
    validProperty = [MSDateTimeTypedProperty new];
    ((MSDateTimeTypedProperty *)validProperty).value =  ((MSDateTimeTypedProperty *)typedProperty).value;
  }
  validProperty.name = [self validateAppCenterPropertyName:typedProperty.name];
  return validProperty;
}

- (NSString *)validateAppCenterPropertyName:(NSString *)propertyKey {
  if ([propertyKey length] > kMSMaxPropertyKeyLength) {
    MSLogWarning([MSAnalytics logTag], @"Typed property '%@': key length cannot exceed %d characters. Property value will be truncated.", propertyKey,
                 kMSMaxPropertyKeyLength);
    return [propertyKey substringToIndex:(kMSMaxPropertyKeyLength - 1)];
  }
  return propertyKey;
}

- (NSString *)validateAppCenterStringTypedPropertyValue:(NSString *)value {
  if ([value length] > kMSMaxPropertyValueLength) {
    MSLogWarning([MSAnalytics logTag], @"Typed property value length cannot exceed %d characters. Property value will be truncated.",
                 kMSMaxPropertyValueLength);
    return [value substringToIndex:(kMSMaxPropertyValueLength - 1)];
  }
  return value;
}

@end
