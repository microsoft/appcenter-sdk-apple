#import <Foundation/Foundation.h>
#import "MSChannelConfiguration.h"
#import "MSLogManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol declaring public common logic for services.
 */
@protocol MSServiceCommon <NSObject>

@required

/**
 * Flag indicating if a service is available or not.
 * It means that the service is started and enabled.
 */
@property(nonatomic, readonly, getter=isAvailable) BOOL available;

/**
 * Log manager.
 */
@property(nonatomic) id<MSLogManager> logManager;

/**
 * The app secret for the SDK.
 */
@property(nonatomic, nonnull) NSString *appSecret;

/**
 * Apply the enabled state to the service.
 *
 * @param isEnabled A boolean value set to YES to enable the service or NO otherwise.
 */
- (void)applyEnabledState:(BOOL)isEnabled;

@optional

/**
 * Service unique key for storage purpose.
 *
 * @discussion: IMPORTANT, This string is used to point to the right storage value for this service.
 * Changing this string results in data lost if previous data is not migrated.
 */
@property(nonatomic, copy, readonly) NSString *groupID;

/**
 * The channel configuration for this service.
 */
// TODO (jaelim): Use this property for channel configuration of each service.
@property(nonatomic, copy, readonly) MSChannelConfiguration *channelConfiguration;

/**
 * The initialization priority for this service.
 */
@property(nonatomic, readonly) MSInitializationPriority initializationPriority;

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

/**
 * Check if the SDK has been properly initialized and the service can be used. Logs an error in case it wasn't.
 *
 * @return a BOOL to indicate proper initialization of the SDK.
 */
- (BOOL)canBeUsed;

/**
 * Start this service with a log manager. Also sets the flag that indicates that a service has been started.
 *
 * @param logManager log manager used to persist and send logs.
 * @param appSecret app secret for the SDK.
 */
- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret;

NS_ASSUME_NONNULL_END

@end
