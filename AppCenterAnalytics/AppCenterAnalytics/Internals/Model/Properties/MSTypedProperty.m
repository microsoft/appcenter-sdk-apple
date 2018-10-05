#import "MSTypedProperty.h"

static NSString *const kMSTypedPropertyType = @"type";

static NSString *const kMSTypedPropertyName = @"name";

@implementation MSTypedProperty

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _type = [coder decodeObjectForKey:kMSTypedPropertyType];
        _name = [coder decodeObjectForKey:kMSTypedPropertyName];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.type forKey:kMSTypedPropertyType];
    [coder encodeObject:self.name forKey:kMSTypedPropertyName];
}

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