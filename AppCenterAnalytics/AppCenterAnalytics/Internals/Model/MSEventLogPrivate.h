#import "MSEventLog.h"

@interface MSEventLog ()

@property NSDictionary *metadataTypeIdMapping;

/**
 * Convert AppCenter properties to Common Schema 3.0 Part C properties.
 *
 * @return A dictionary of key-value pairs.
 */
- (NSDictionary<NSString *, NSObject *> *)convertTypedPropertiesToCSProperties;

@end
