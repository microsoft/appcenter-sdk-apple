#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@interface MSPushLog : MSAbstractLog

/**
 * Push token for push service
 */
@property(nonatomic) NSString *pushToken;

@end
