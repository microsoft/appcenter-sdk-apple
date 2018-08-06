#import <Foundation/Foundation.h>

@protocol MSAuthenticationProviderDelegate;

/**
 *  Different authentication types, e.g. MSA, AAD,... .
 */
typedef NS_ENUM(NSUInteger, MSAuthenticationType) {

  /**
   *  AuthenticationType MSA.
   */
  MSAuthenticationTypeMSA
};

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthenticationProvider : NSObject

/**
 * The type.
 */
@property(nonatomic, readonly) MSAuthenticationType type;

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
@property(nonatomic, readonly) id<MSAuthenticationProviderDelegate> delegate;

/**
 * Create a new authentication provider.
 * @param type The type for the provider, e.g. MSA.
 * @param ticketKey The ticket key for the provider.
 * @param delegate The delegate that will be used to get a current authentication token.
 * @return A new authentication provider.
 */
- (instancetype)initWithAuthenticationType:(MSAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                                  delegate:(id<MSAuthenticationProviderDelegate>)delegate;

- (void)acquireTokenAsync;

@end

NS_ASSUME_NONNULL_END
