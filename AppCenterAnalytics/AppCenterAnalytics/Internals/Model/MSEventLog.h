#import "MSAnalyticsLog.h"

@interface MSEventLog : MSAnalyticsLog

/**
 * Unique identifier for this event.
 */
@property(nonatomic, copy) NSString *eventId;

@end
