#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSChannelUnitProtocol;
@class MSChannelUnitConfiguration;

/**
 * `MSChannelGroupProtocol` represents a kind of channel that contains
 * constituent MSChannelUnit objects. When an operation from the `MSChannelProtocol`
 * is performed on the group, that operation should be propagated to its
 * constituent MSChannelUnit objects.
 */
@protocol MSChannelGroupProtocol <MSChannelProtocol>

/**
 * Initialize a channel with the given configuration.
 *
 * @param configuration channel configuration.
 */
- (id<MSChannelUnitProtocol>)addChannelUnitWithConfiguration:(MSChannelUnitConfiguration *)configuration;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param logUrl base URL to use for backend communication.
 */
- (void)setLogUrl:(NSString *)logUrl;

@end

NS_ASSUME_NONNULL_END
