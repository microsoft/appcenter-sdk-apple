#import "MSSessionContext.h"
#import "MSSessionTracker.h"

@interface MSSessionTracker ()

/**
 * Session context. This should be the shared instance, unless tests need to override.
 */
@property(nonatomic) MSSessionContext *context;

/**
 * Flag to indicate if session tracking has started or not.
 */
@property(nonatomic) BOOL started;

/**
 *  Renew session Id.
 */
- (void)renewSessionId;

@end
