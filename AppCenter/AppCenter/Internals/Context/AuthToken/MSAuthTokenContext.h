#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token that the Identity service provides.
 * This enables all App Center modules to access the token, and receive a notification when the token changes.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Auth token.
 */
@property(nonatomic, nullable) NSString *authToken;

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
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
