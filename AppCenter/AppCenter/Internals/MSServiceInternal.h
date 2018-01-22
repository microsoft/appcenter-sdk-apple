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
 * The app secret for the SDK.
 */
@property(nonatomic) NSString *appSecret;

/**
 * Get the unique instance.
 *
 * @return The unique instance.
 */
+ (instancetype)sharedInstance;

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

@end
