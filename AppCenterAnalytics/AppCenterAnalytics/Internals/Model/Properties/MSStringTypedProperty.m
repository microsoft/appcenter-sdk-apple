#import "MSStringTypedProperty.h"

@implementation MSStringTypedProperty

- (instancetype)init {
    if ((self = [super init])) {
        self.type = @"string";
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _value = [coder decodeObjectForKey:kMSTypedPropertyValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.value forKey:kMSTypedPropertyValue];
}

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary *dict = [super serializeToDictionary];
    dict[@"value"] = self.value;
    return dict;
}

@end