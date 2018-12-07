#import "AppCenter+Internal.h"
#import "MSACModelConstants.h"
#import "MSAnalyticsConstants.h"
#import "MSAnalyticsInternal.h"
#import "MSBooleanTypedProperty.h"
#import "MSCSData.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSConstants+Internal.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventLogPrivate.h"
#import "MSEventPropertiesInternal.h"
#import "MSLongTypedProperty.h"
#import "MSMetadataExtension.h"
#import "MSStringTypedProperty.h"

static NSString *const kMSTypeEvent = @"event";

static NSString *const kMSId = @"id";

static NSString *const kMSTypedProperties = @"typedProperties";

@implementation MSEventLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeEvent;
    _metadataTypeIdMapping = @{
      kMSLongTypedPropertyType : @(kMSLongMetadataTypeId),
      kMSDoubleTypedPropertyType : @(kMSDoubleMetadataTypeId),
      kMSDateTimeTypedPropertyType : @(kMSDateTimeMetadataTypeId)
    };
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  if (self.eventId) {
    dict[kMSId] = self.eventId;
  }
  if (self.typedProperties) {
    dict[kMSTypedProperties] = [self.typedProperties serializeToArray];
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.eventId;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSEventLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSEventLog *eventLog = (MSEventLog *)object;
  return ((!self.eventId && !eventLog.eventId) || [self.eventId isEqualToString:eventLog.eventId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _eventId = [coder decodeObjectForKey:kMSId];
    _typedProperties = [coder decodeObjectForKey:kMSTypedProperties];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.eventId forKey:kMSId];
  [coder encodeObject:self.typedProperties forKey:kMSTypedProperties];
}

#pragma mark - MSAbstractLog

- (MSCommonSchemaLog *)toCommonSchemaLogForTargetToken:(NSString *)token flags:(MSFlags)flags {
  MSCommonSchemaLog *csLog = [super toCommonSchemaLogForTargetToken:token flags:flags];

  // Event name goes to part A.
  csLog.name = self.name;

  // Metadata extension must accompany data.
  // Event properties goes to part C.
  [self setPropertiesAndMetadataForCSLog:csLog];
  csLog.tag = self.tag;
  return csLog;
}

#pragma mark - Helper

- (void)setPropertiesAndMetadataForCSLog:(MSCommonSchemaLog *)csLog {
  NSMutableDictionary *csProperties;
  NSMutableDictionary *metadata;
  if (self.typedProperties) {
    csProperties = [NSMutableDictionary new];
    metadata = [NSMutableDictionary new];
    NSString *baseTypePrefix = [NSString stringWithFormat:@"%@.", kMSDataBaseType];
    NSString *baseDataPrefix = [NSString stringWithFormat:@"%@.", kMSDataBaseData];

    // If baseType is set and valid, make sure it's paired with at least 1 "baseData.*" property.
    if ([self.typedProperties.properties[kMSDataBaseType] isKindOfClass:[MSStringTypedProperty class]]) {
      BOOL foundBaseData = NO;
      for (NSString *key in [self.typedProperties.properties allKeys]) {
        if ([key hasPrefix:baseDataPrefix]) {
          foundBaseData = YES;
          break;
        }
      }
      if (!foundBaseData) {
        MSLogWarning([MSAnalytics logTag], @"baseType was set but baseData is missing.");
        [self.typedProperties.properties removeObjectForKey:kMSDataBaseType];
      }
    }

    // If there is no valid "baseType" property, there must not be any "baseData.*" property.
    else {
      BOOL removedBaseData = NO;
      for (NSString *key in [self.typedProperties.properties allKeys]) {
        if ([key hasPrefix:baseDataPrefix]) {
          [self.typedProperties.properties removeObjectForKey:key];
          removedBaseData = YES;
        }
      }
      if (removedBaseData) {
        MSLogWarning([MSAnalytics logTag], @"baseData was set but baseType is missing or invalid.");
      }

      // Base type might be set but invalid, so remove it.
      [self.typedProperties.properties removeObjectForKey:kMSDataBaseType];
    }

    // Add typed properties and metadata to the common schema log fields.
    for (MSTypedProperty *typedProperty in [self.typedProperties.properties objectEnumerator]) {

      // Validate baseType is not an object, meaning it should not have dot.
      if ([[typedProperty name] hasPrefix:baseTypePrefix]) {
        MSLogWarning([MSAnalytics logTag], @"baseType must not be an object.");
        continue;
      }

      // Validate baseData is an object, meaning it has at least 1 dot.
      if ([[typedProperty name] isEqualToString:kMSDataBaseData]) {
        MSLogWarning([MSAnalytics logTag], @"baseData must be an object.");
        continue;
      }

      // Convert property.
      [self addTypedProperty:typedProperty toCSMetadata:metadata andCSProperties:csProperties];
    }
  }
  if (csProperties.count != 0) {
    csLog.data = [MSCSData new];
    csLog.data.properties = csProperties;
  }
  if (metadata.count != 0) {
    csLog.ext.metadataExt = [MSMetadataExtension new];
    csLog.ext.metadataExt.metadata = metadata;
  }
}

- (void)addTypedProperty:(MSTypedProperty *)typedProperty
            toCSMetadata:(NSMutableDictionary *)csMetadata
         andCSProperties:(NSMutableDictionary *)csProperties {
  NSNumber *typeId = self.metadataTypeIdMapping[typedProperty.type];

  // If the key contains a '.' then it's nested objects (i.e: "a.b":"value" => {"a":{"b":"value"}}).
  NSArray *csKeys = [typedProperty.name componentsSeparatedByString:@"."];
  NSMutableDictionary *propertyTree = csProperties;
  NSMutableDictionary *metadataTree = csMetadata;

  /*
   * Keep track of the subtree that contains all the metadata levels added in the for loop.
   * Thus if it needs to be removed, a second traversal is not needed.
   * The metadata should be cleaned up if the property is not added due to a key collision.
   */
  NSMutableDictionary *metadataSubtreeParent = nil;
  for (NSUInteger i = 0; i < csKeys.count - 1; i++) {
    id key = csKeys[i];
    if (![(NSObject *)propertyTree[key] isKindOfClass:[NSMutableDictionary class]]) {
      if (propertyTree[key]) {
        propertyTree = nil;
        break;
      }
      propertyTree[key] = [NSMutableDictionary new];
    }
    propertyTree = propertyTree[key];
    if (typeId) {
      if (!metadataTree[kMSFieldDelimiter]) {
        metadataTree[kMSFieldDelimiter] = [NSMutableDictionary new];
        metadataSubtreeParent = metadataSubtreeParent ?: metadataTree;
      }
      if (!metadataTree[kMSFieldDelimiter][key]) {
        metadataTree[kMSFieldDelimiter][key] = [NSMutableDictionary new];
      }
      metadataTree = metadataTree[kMSFieldDelimiter][key];
    }
  }
  id lastKey = csKeys.lastObject;
  BOOL didAddTypedProperty = [self addTypedProperty:typedProperty toPropertyTree:propertyTree withKey:lastKey];
  if (typeId && didAddTypedProperty) {
    if (!metadataTree[kMSFieldDelimiter]) {
      metadataTree[kMSFieldDelimiter] = [NSMutableDictionary new];
    }
    metadataTree[kMSFieldDelimiter][lastKey] = typeId;
  } else if (metadataSubtreeParent) {
    [metadataSubtreeParent removeObjectForKey:kMSFieldDelimiter];
  }
}

- (BOOL)addTypedProperty:(MSTypedProperty *)typedProperty toPropertyTree:(NSMutableDictionary *)propertyTree withKey:(NSString *)key {
  if (!propertyTree || propertyTree[key]) {
    MSLogWarning(MSAnalytics.logTag, @"Property key '%@' already has a value, choosing one.", key);
    return NO;
  }
  if ([typedProperty isKindOfClass:[MSStringTypedProperty class]]) {
    MSStringTypedProperty *stringProperty = (MSStringTypedProperty *)typedProperty;
    propertyTree[key] = stringProperty.value;
  } else if ([typedProperty isKindOfClass:[MSBooleanTypedProperty class]]) {
    MSBooleanTypedProperty *boolProperty = (MSBooleanTypedProperty *)typedProperty;
    propertyTree[key] = @(boolProperty.value);
  } else if ([typedProperty isKindOfClass:[MSLongTypedProperty class]]) {
    MSLongTypedProperty *longProperty = (MSLongTypedProperty *)typedProperty;
    propertyTree[key] = @(longProperty.value);
  } else if ([typedProperty isKindOfClass:[MSDoubleTypedProperty class]]) {
    MSDoubleTypedProperty *doubleProperty = (MSDoubleTypedProperty *)typedProperty;
    propertyTree[key] = @(doubleProperty.value);
  } else if ([typedProperty isKindOfClass:[MSDateTimeTypedProperty class]]) {
    MSDateTimeTypedProperty *dateProperty = (MSDateTimeTypedProperty *)typedProperty;
    propertyTree[key] = [MSUtility dateToISO8601:dateProperty.value];
  }
  return YES;
}

@end
