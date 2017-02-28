#import <Foundation/Foundation.h>
#import "MobileCenter+Internal.h"

@interface MSPushLog : MSAbstractLog

/**
 * Device token for push service
 */
@property(nonatomic) NSString *deviceToken;

@end
