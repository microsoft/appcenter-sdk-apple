#import "MSUtility+PropertyValidation.h"

#import "MSConstants+Internal.h"
#import "MSLogger.h"

@implementation NSObject (MSUtility_PropertyValidation)

+ (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                        type:(NSString *)logType
                                            withConsoleLogTag:(NSString *)consoleLogTag {
  NSMutableDictionary<NSString *, NSString *> *validProperties = [NSMutableDictionary new];
  for (id key in properties) {

    // Don't send more properties than we can.
    if ([validProperties count] >= kMSMaxPropertiesPerLog) {
      MSLogWarning(consoleLogTag, @"%@ '%@' : properties cannot contain more than %d items. Skipping other properties.",
                   logType, logName, kMSMaxPropertiesPerLog);
      break;
    }
    if (![key isKindOfClass:[NSString class]] || ![properties[key] isKindOfClass:[NSString class]]) {
      continue;
    }

    // Validate key.
    NSString *strKey = key;
    if ([strKey length] < kMSMinPropertyKeyLength) {
      MSLogWarning(consoleLogTag, @"%@ '%@' : a property key cannot be null or empty. Property will be skipped.",
                   logType, logName);
      continue;
    }
    if ([strKey length] > kMSMaxPropertyKeyLength) {
      MSLogWarning(consoleLogTag, @"%@ '%@' : property %@ : property key length cannot be longer than %d "
                                 @"characters. Property key will be truncated.",
                   logType, logName, strKey, kMSMaxPropertyKeyLength);
      strKey = [strKey substringToIndex:kMSMaxPropertyKeyLength];
    }

    // Validate value.
    NSString *value = properties[key];
    if ([value length] > kMSMaxPropertyValueLength) {
      MSLogWarning(consoleLogTag, @"%@ '%@' : property '%@' : property value cannot be longer than %d "
                                 @"characters. Property value will be truncated.",
                   logType, logName, strKey, kMSMaxPropertyValueLength);
      value = [value substringToIndex:kMSMaxPropertyValueLength];
    }

    // Save valid properties.
    [validProperties setObject:value forKey:strKey];
  }
  return validProperties;
}

@end
