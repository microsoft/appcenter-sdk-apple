// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSIdentityErrors.h"
#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

@class MSUserInformation;

/**
 * Completion handler triggered when sign-in completed.
 *
 * @param userInformation User information for signed in user.
 * @param error Error for sign-in failure.
 */
typedef void (^MSSignInCompletionHandler)(MSUserInformation *_Nullable userInformation, NSError *_Nullable error);

/**
 * App Center Identity service.
 */
@interface MSIdentity : MSServiceAbstract

#if TARGET_OS_IOS
/**
 * Process URL request for the service.
 *
 * @param url  The url with parameters.
 *
 * @return `YES` if the URL is intended for App Center Identity and your application, `NO` otherwise.
 *
 * @discussion Place this method call into your app delegate's openURL method.
 */
+ (BOOL)openURL:(NSURL *)url;
#endif

/**
 * Sign-in to get user information.
 *
 * @param completionHandler Callback that is invoked after sign-in completed. @c `MSSignInCompletionHandler`.
 */
+ (void)signInWithCompletionHandler:(MSSignInCompletionHandler _Nullable)completionHandler;

/**
 * Sign out to clear user information.
 */
+ (void)signOut;

/**
 * Sets the base URL for the remote configuration file.
 *
 * @param configUrl The base URL of the remote configuration file.
 */
+ (void)setConfigUrl:(NSString *)configUrl;

@end

NS_ASSUME_NONNULL_END
