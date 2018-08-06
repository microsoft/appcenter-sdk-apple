#import <Foundation/Foundation.h>

@protocol MSAnalyticsAuthenticationProviderDelegate;

/**
 *  Different authentication types, e.g. MSA, AAD,... .
 */
typedef NS_ENUM(NSUInteger, MSAnalyticsAuthenticationType) {

  /**
   *  AuthenticationType MSA.
   */
  MSAnalyticsAuthenticationTypeMSA
};

NS_ASSUME_NONNULL_BEGIN

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
 * The delegate that will be used to get an updated authentication token.
 */
@property(nonatomic, readonly) id<MSAnalyticsAuthenticationProviderDelegate> delegate;

/**
 * Create a new authentication provider.
 * @param type The type for the provider, e.g. MSA.
 * @param ticketKey The ticket key for the provider.
 * @param delegate The delegate that will be used to get a current authentication token.
 * @return A new authentication provider.
 */
- (instancetype)initWithAuthenticationType:(MSAnalyticsAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                                  delegate:(id<MSAnalyticsAuthenticationProviderDelegate>)delegate;

- (void)acquireTokenAsync;

@end

NS_ASSUME_NONNULL_END
