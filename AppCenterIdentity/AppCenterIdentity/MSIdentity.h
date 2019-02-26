#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center Identity service.
 */
@interface MSIdentity : MSServiceAbstract

/**
 * Process URL request for the service.
 *
 * @param url  The url with parameters.
 *
 * @return `YES` if the URL is intended for App Center Idenntity and your application, `NO` otherwise.
 *
 * @discussion Place this method call into your app delegate's openURL method.
 */
+ (BOOL)openURL:(NSURL *)url;

/**
 * SignIn to get user information.
 */
+ (void)signIn;

/**
 * SignOut to clear user information.
 */
+ (void)signOut;

@end

NS_ASSUME_NONNULL_END
