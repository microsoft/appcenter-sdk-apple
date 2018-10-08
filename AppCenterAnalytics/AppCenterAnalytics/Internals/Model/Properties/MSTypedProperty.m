#import "MSTypedProperty.h"
#import "MSAnalyticsInternal.h"
#import "MSConstants+Internal.h"
#import "MSLogger.h"

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

- (instancetype)createValidCopyForAppCenter {
    if ([self.name length] > 125) {
        MSLogWarning([MSAnalytics logTag], @"Typed property '%@': property key length cannot exceed %i characters. Property key will be truncated.",
            self.name, kMSMaxPropertyKeyLength);
    }
    return nil;
}
- (instancetype)createValidCopyForOneCollector {
    return nil;
}

@end