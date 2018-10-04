#import "MSTypedProperty.h"

static NSString *const kMSTypedPropertyType = @"type";

static NSString *const kMSTypedPropertyName = @"name";

static NSString *const kMSTypedPropertyValue = @"value";

@implementation MSTypedProperty

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary * dict = [NSMutableDictionary new];
    dict[kMSTypedPropertyType] = self.type;
    dict[kMSTypedPropertyName] = self.name;
    return dict;
}

@end