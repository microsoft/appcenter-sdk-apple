#import "MSEventLog.h"

@interface MSEventLog ()

@property NSDictionary *metadataTypeIdMapping;

/**
 * Convert AppCenter properties to Common Schema 3.0 Part C properties.
 */
- (void)setPropertiesAndMetadataForCSLog:(MSCommonSchemaLog *)csLog;

@end
