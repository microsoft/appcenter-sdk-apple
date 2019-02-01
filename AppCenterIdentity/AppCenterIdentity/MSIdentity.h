#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center Identity service.
 */
@interface MSIdentity : MSServiceAbstract

/**
 * The callback method to be called when the app receives openURL response.
 *
 * @param url URL from your application delegate's openURL handler into AppCenterIdentitiy for web authentication sessions
 */
+ (void)handleUrlResponse:(NSURL *)url;

/**
 * Login to get user information.
 */
+ (void)login;

@end

NS_ASSUME_NONNULL_END
