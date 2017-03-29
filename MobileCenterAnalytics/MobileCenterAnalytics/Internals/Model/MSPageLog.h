#import <Foundation/Foundation.h>

#import "MSLogWithProperties.h"
#import "MobileCenter+Internal.h"

@interface MSPageLog : MSLogWithProperties

/** Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
