#import "MSConstants+Internal.h"
#import "MSStringTypedProperty.h"

@implementation MSStringTypedProperty

- (instancetype)init {
    if ((self = [super init])) {
        self.type = kMSStringTypedPropertyType;
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

- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary *dict = [super serializeToDictionary];
    dict[kMSTypedPropertyValue] = self.value;
    return dict;
}

@end
