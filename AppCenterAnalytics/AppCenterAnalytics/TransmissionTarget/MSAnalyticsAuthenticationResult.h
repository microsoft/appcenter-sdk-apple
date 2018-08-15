#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsAuthenticationResult : NSObject

/**
 * The authentication token.
 */
@property (nonatomic, copy, readonly) NSString *token;

/**
 * The expiry date for the token.
 */
@property (nonatomic, readonly) NSDate *expiryDate;

/**
 * Initialize a new instance of MSAnalyticsAuthenticationResult.
 *
 * @param token The authentication token.
 * @param expiryDate The expiry date.
 * @return A new instance.
 */
- (instancetype)initWithToken:(NSString *)token expiryDate:(NSDate *)expiryDate;

@end

NS_ASSUME_NONNULL_END
