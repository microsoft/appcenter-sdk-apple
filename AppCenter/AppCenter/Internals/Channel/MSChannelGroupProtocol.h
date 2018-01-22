#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSChannelUnitProtocol;
@class MSChannelUnitConfiguration;

/**
 * TODO add some comments
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
