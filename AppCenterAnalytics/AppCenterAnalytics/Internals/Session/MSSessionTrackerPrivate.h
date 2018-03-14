#import "MSSessionTracker.h"

@interface MSSessionTracker ()

/**
 * Session context. This should be the shared instance, unless tests need
 * to override.
 */
@property(nonatomic) MSSessionContext *context;

/**
 *  Renew session Id.
 */
- (void)renewSessionId;


@end
