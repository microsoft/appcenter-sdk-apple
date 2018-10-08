#import "MSLogWithNameAndProperties.h"
#import "MSEventProperties.h"

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
