#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"

@protocol MSChannelUnitProtocol;
@class MSChannelConfiguration;

/**
 * TODO add some comments
 */
@protocol MSChannelGroupProtocol <MSChannelProtocol>

/**
 * Initialize a channel with the given configuration.
 *
 * @param configuration channel configuration.
 */
- (id<MSChannelUnitProtocol>)initChannelUnitWithConfiguration:(MSChannelConfiguration *)configuration;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param logUrl base URL to use for backend communication.
 */
- (void)setLogUrl:(NSString *)logUrl;

@end
