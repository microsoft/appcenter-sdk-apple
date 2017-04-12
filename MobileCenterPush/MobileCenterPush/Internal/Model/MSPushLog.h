#import <Foundation/Foundation.h>
#import "MobileCenter+Internal.h"

@interface MSPushLog : MSAbstractLog

/**
 * Push token for push service
 */
@property(nonatomic) NSString *pushToken;

@end
