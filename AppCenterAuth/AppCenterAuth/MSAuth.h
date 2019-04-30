// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#if TARGET_OS_IOS
#import <UIKit/UIApplication.h>
#endif

#import "MSAuthErrors.h"
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
 * App Center Auth service.
 */
@interface MSAuth : MSServiceAbstract

#if TARGET_OS_IOS
/**
 * Process URL request for the service.
 *
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param options A dictionary of URL handling options. For information about the possible keys in this dictionary and how to handle them,
 * @see UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
 *
 * @return `YES` if the URL is intended for App Center Auth and your application, `NO` otherwise.
 *
 * @discussion Place this method call into your app delegate's openURL method.
 */
+ (BOOL)openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;
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
