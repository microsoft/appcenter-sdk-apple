#import "MSStringTypedProperty.h"
#import "MSAnalyticsInternal.h"
#import "MSConstants+Internal.h"
#import "MSLogger.h"

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

- (instancetype)createValidCopyForAppCenter {
    [super createValidCopyForAppCenter];
    MSStringTypedProperty *validProperty = [MSStringTypedProperty new];
    if ([self.value length] > kMSMaxPropertyValueLength) {
        MSLogWarning([MSAnalytics logTag], @"Typed property '%@': property value length cannot exceed %i characters. Property value will be truncated.", self
            .name, kMSMaxPropertyValueLength);
    }
    validProperty.name = [self.name substringToIndex:kMSMaxPropertyKeyLength];
    validProperty.value = [self.value substringToIndex:kMSMaxPropertyValueLength];
    return validProperty;
}

- (instancetype)createValidCopyForOneCollector {
    return self;
}

@end