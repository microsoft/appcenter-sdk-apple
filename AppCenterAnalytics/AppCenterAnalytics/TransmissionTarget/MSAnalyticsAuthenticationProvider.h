#import <Foundation/Foundation.h>

@protocol MSAnalyticsAuthenticationProviderDelegate;
@class MSAnalyticsAuthenticationResult;

/**
 * Different authentication types, e.g. MSA Compact, MSA Delegate, AAD,... .
 */
typedef NS_ENUM(NSUInteger, MSAnalyticsAuthenticationType) {

  /**
   * AuthenticationType MSA Compact.
   */
  MSAnalyticsAuthenticationTypeMsaCompact,

  /**
   * AuthenticationType MSA Delegate.
   */
  MSAnalyticsAuthenticationTypeMsaDelegate
};

NS_ASSUME_NONNULL_BEGIN

/**
 * Completion handler that returns the authentication token.
 */
typedef MSAnalyticsAuthenticationResult *_Nullable (
    ^MSAcquireTokenCompletionBlock)(void);

@interface MSAnalyticsAuthenticationProvider : NSObject

/**
 * The type.
 */
@property(nonatomic, readonly) MSAnalyticsAuthenticationType type;

/**
 * The ticket key for this authentication provider.
 */
@property(nonatomic, readonly, copy) NSString *ticketKey;

/**
 * The ticket key as hash.
 */
@property(nonatomic, readonly, copy) NSString *ticketKeyHash;

/**
 * Completion block that will be used to get an updated authentication token.
 */
@property(nonatomic, readonly, copy)
    MSAcquireTokenCompletionBlock completionHandler;

/**
 * Create a new authentication provider.
 *
 * @param type The type for the provider, e.g. MSA.
 * @param ticketKey The ticket key for the provider.
 * @param completionHandler The completion block that will be used to get a
 * current authentication token.
 *
 * @return A new authentication provider.
 */
- (instancetype)initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                         completionHandler:
                             (MSAcquireTokenCompletionBlock)completionHandler;

/**
 * Check expiration.
 */
- (void)checkTokenExpiry;

@end

NS_ASSUME_NONNULL_END
