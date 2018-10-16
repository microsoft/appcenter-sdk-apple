#import "MSLogWithNameAndProperties.h"

@class MSEventProperties;
@class MSMetadataExtension;

//TODO move these into a constants file
static const int kMSLongMetadataTypeId = 4;

static const int kMSDoubleMetadataTypeId = 6;

static const int kMSDateTimeMetadataTypeId = 9;

@interface MSEventLog : MSLogWithNameAndProperties

/**
 * Unique identifier for this event.
 */
@property(nonatomic, copy) NSString *eventId;

/**
 * Event properties.
 */
@property(nonatomic) MSEventProperties *typedProperties;

@end
