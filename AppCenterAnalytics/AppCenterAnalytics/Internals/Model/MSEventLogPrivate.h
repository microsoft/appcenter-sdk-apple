#import "MSEventLog.h"

@interface MSEventLog ()

/**
 * Convert AppCenter properties to Common Schema 3.0 Part C properties.
 *
 * @param acProperties The AppCenter properties.
 *
 * @return A dictionary of key-value pairs.
 */
- (NSDictionary<NSString *, NSObject *> *)convertACPropertiesToCSproperties:
    (NSDictionary<NSString *, NSString *> *)acProperties;

@end
