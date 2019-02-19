#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@interface MSPushLog : MSAbstractLog

/**
 * Push token for push service
 */
@property(nonatomic, copy) NSString *pushToken;

@end
