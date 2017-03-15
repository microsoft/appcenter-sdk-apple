#import "MSService.h"
#import "MSServiceCommon.h"
#import "MSLogManager.h"

/**
 *  Protocol declaring all the logic of a service. This is what concrete services needs to conform to.
 *  The difference is that MSServiceCommon is public, while MSServiceInternal is private.
 *  Some properties are present in both, which is counter-intuitive but the way we implemented this
 *  to achieve abstraction and not have empty implementations in MSServiceAbstract.
 */
@protocol MSServiceInternal <MSService, MSServiceCommon>

/**
 * Service unique key for storage purpose.
 * @discussion: IMPORTANT, This string is used to point to the right storage value for this service.
 * Changing this string results in data loss if previous data is not migrated.
 */
@property(nonatomic, copy, readonly) NSString *groupID;

/**
 * The channel priority for this service. Defined here as well as in MSServiceCommon to achieve abstraction.
 */
@property(nonatomic, readonly) MSPriority priority;

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
 */
// FIXME: need implement this static method in all services after merging
+ (NSString *)serviceName;

/**
 * Get the log tag for this service.
 *
 * @return A name of logger tag for this service.
 */
+ (NSString *)logTag;

@end
