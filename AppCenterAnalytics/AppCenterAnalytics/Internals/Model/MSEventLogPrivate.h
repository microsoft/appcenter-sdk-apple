#import "MSEventLog.h"

static const int kMSLongMetadataTypeId = 4;

static const int kMSDoubleMetadataTypeId = 6;

static const int kMSDateTimeMetadataTypeId = 9;

@interface MSEventLog ()

/**
 * Maps each typed property string identifier to a CS type identifier.
 */
@property(nonatomic) NSDictionary *metadataTypeIdMapping;

/**
 * Convert AppCenter properties to Common Schema 3.0 Part C properties.
 */
- (void)setPropertiesAndMetadataForCSLog:(MSCommonSchemaLog *)csLog;

@end
