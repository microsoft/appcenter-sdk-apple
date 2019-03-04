#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token that the Identity service provides.
 * This enables all App Center modules to access the token, and receive a notification when the token changes.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Cached authorization token.
 */
@property(nullable, atomic, readonly) NSString *authToken;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Add delegate.
 *
 * @param delegate Delegate.
 */
- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Remove delegate.
 *
 * @param delegate Delegate.
 */
- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Clear cached token and account id.
 */
- (void)clearAuthToken;

/**
 * Set current auth token and account id.
 */
- (void)setAuthToken:(NSString *)authToken withAccountId:(NSString *)accountId;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
