#import <Foundation/Foundation.h>

#import "MSConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class MSChannelUnitConfiguration;
@protocol MSChannelGroupProtocol;
@protocol MSChannelUnitProtocol;

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
 * Channel group.
 */
@property(nonatomic) id<MSChannelGroupProtocol> channelGroup;

/**
 * Channel unit.
 */
@property(nonatomic) id<MSChannelUnitProtocol> channelUnit;

/**
 * The app secret for the SDK.
 */
@property(nonatomic, nonnull) NSString *appSecret;

/**
 * The default transmission target token.
 */
@property(nonatomic, nonnull) NSString *defaultTransmissionTargetToken;

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
@property(nonatomic, copy, readonly) NSString *groupId;

/**
 * The channel configuration for this service.
 */
@property(nonatomic, readonly) MSChannelUnitConfiguration *channelUnitConfiguration;

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
 * Start this service with a channel group. Also sets the flag that indicates that a service has been started.
 *
 * @param channelGroup channel group used to persist and send logs.
 * @param appSecret app secret for the SDK.
 * @param token default transmission target token.
 *
 * @discussion Note that this is defined both here and in MSServiceAbstract.h. This is intentional, and due to
 * the way the classes are factored.
 */
- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token;

/**
 * Checks if the service needs the application secret.
 *
 * @return `YES` if the application secret is required, `NO` otherwise.
 */
- (BOOL)isAppSecretRequired;

NS_ASSUME_NONNULL_END

@end
