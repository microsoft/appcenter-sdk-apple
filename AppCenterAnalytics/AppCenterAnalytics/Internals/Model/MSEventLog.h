#import <Foundation/Foundation.h>

#import "MSLogWithProperties.h"

@interface MSEventLog : MSLogWithProperties

/**
 * Unique identifier for this event.
 */
@property(nonatomic, copy) NSString *eventId;

/**
 * Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
