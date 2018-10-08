#import "MSLongTypedProperty.h"
#import "MSConstants+Internal.h"

@implementation MSLongTypedProperty

- (instancetype)init {
    if ((self = [super init])) {
        self.type = @"long";
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _value = [coder decodeInt64ForKey:kMSTypedPropertyValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInt64:self.value forKey:kMSTypedPropertyValue];
}

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary *dict = [super serializeToDictionary];
    dict[kMSTypedPropertyValue] = @(self.value);
    return dict;
}

- (instancetype)createValidCopyForAppCenter {
    [super createValidCopyForAppCenter];
    MSLongTypedProperty *validProperty = [MSLongTypedProperty new];
    validProperty.name = [self.name substringToIndex:kMSMaxPropertyKeyLength];
    validProperty.value = self.value;
    return validProperty;
}

- (instancetype)createValidCopyForOneCollector {
    return self;
}

@end