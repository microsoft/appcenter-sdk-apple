#import "MSCustomProperties.h"

/**
 *  Private declarations for MSCustomProperties.
 */
@interface MSCustomProperties ()

/**
 * Create an immutable copy of the properties dictionary to use in synchronized scenarios.
 *
 * @return An immutable copy of properties.
 */
- (NSDictionary<NSString *, NSObject *> *)propertiesImmutableCopy;

@end
