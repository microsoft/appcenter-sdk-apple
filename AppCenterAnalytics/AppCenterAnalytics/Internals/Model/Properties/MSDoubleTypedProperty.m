#import "MSDoubleTypedProperty.h"

extern NSString *const kMSTypedPropertyValue;

@implementation MSDoubleTypedProperty

- (instancetype)init {
    if ((self = [super init])) {
        self.type = @"double";
    }
    return self;
}

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary *dict = [super serializeToDictionary];
    dict[kMSTypedPropertyValue] = self.value;
    return dict;
}

@end