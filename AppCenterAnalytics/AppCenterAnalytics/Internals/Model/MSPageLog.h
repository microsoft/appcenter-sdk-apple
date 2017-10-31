#import <Foundation/Foundation.h>
#import "AppCenter+Internal.h"
#import "MSLogWithProperties.h"

@interface MSPageLog : MSLogWithProperties

/**
 * Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
