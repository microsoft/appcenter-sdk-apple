#import "MSService.h"
#import "MSServiceCommon.h"

/**
 *  Protocol declaring all the logic of a service. This is what concrete services needs to conform to.
 *  The difference is that MSServiceCommon is public, while MSServiceInternal is private.
 *  Some properties are present in both, which is counter-intuitive but the way we implemented this
 *  to achieve abstraction and not have empty implementations in MSServiceAbstract.
 */
@protocol MSServiceInternal <MSService, MSServiceCommon>

/**
 * The initialization priority for this service. Defined here as well as in MSServiceCommon to achieve abstraction.
 */
@property(nonatomic, readonly) MSInitializationPriority initializationPriority;

/**
 * Get the unique instance.
 *
 * @return The unique instance.
 */
+ (instancetype)sharedInstance;

/**
 * Service unique key for storage purpose.
 *
 * @discussion: IMPORTANT, This string is used to point to the right storage value for this service.
 * Changing this string results in data lost if previous data is not migrated.
 */
@property(nonatomic, copy, readonly) NSString *groupId;

/**
 * Get a service name.
 *
 * @return the service name.
 *
 * @discussion This is used to initialize each service.
 */
+ (NSString *)serviceName;

/**
 * Get the log tag for this service.
 *
 * @return A name of logger tag for this service.
 */
+ (NSString *)logTag;

/**
 * Start this service with a channel group. Also sets the flag that indicates that a service has been started.
 *
 * @param channelGroup channel group used to persist and send logs.
 * @param appSecret app secret for the SDK.
 * @param tenantId default tenant id for this service.
 */
- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup appSecret:(NSString *)appSecret tenantId:(NSString *)tenantId;

@end
