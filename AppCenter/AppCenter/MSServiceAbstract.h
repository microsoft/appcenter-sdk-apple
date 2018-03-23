#import <Foundation/Foundation.h>

#import "MSService.h"

@protocol MSChannelGroupProtocol;

/**
 * Abstraction of services common logic.
 * This class is intended to be subclassed only not instantiated directly.
 */
@interface MSServiceAbstract : NSObject <MSService>

/**
 * Start this service with a channel group. Also sets the flag that indicates that a service has been started.
 *
 * @param channelGroup channel group used to persist and send logs.
 * @param appSecret app secret for the SDK.
 * @param token default transmission target token for this service.
 */
- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup appSecret:(NSString *)appSecret transmissionTargetToken:(NSString *)token;

@end

