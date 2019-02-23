#import <Foundation/Foundation.h>

@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token that the Identity service provides.
 * This enables all App Center modules to access the token, and receive a notification when the token changes.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Add delegate.
 *
 * @param delegate Delegate.
 */
- (void)addDelegate:(id<MSAuthTokenContextDelegate> _Nonnull)delegate;

/**
 * Remove delegate.
 *
 * @param delegate Delegate.
 */
- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Clears cached token and account id.
 */
- (void)clearAuthToken;

/**
 * Sets current auth token and account id.
 */
- (void)setAuthToken:(NSString *_Nonnull)authToken withAccountId:(NSString *_Nonnull)accountId;

/**
 * Retrieves auth token.
 */
- (NSString *)getAuthToken;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end
