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
 * Channel unit.
 */
@property(nonatomic) id<MSChannelUnitProtocol> channelUnit;

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

NS_ASSUME_NONNULL_END

@end
