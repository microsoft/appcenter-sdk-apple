// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSServiceAbstract.h"
#import "MSUserInformation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Completion handler triggered when sign-in completed.
 *
 * @param userInformation User information for signed in user.
 * @param error Error for sign-in failure.
 */
typedef void (^MSSignInCompletionHandler)(MSUserInformation *_Nullable userInformation, NSError *_Nullable error);

/**
 * Error code for Identity.
 */
NS_ENUM(NSInteger){kMSIdentityErrorServiceDisabled = -420000, kMSIdentityErrorPreviousSignInRequestInProgress = -420001,
                   kMSIdentityErrorSignInBackgroundOrNotConfigured = -420002, kMSIdentityErrorSignInWhenNoConnection = -420003};

/**
 * Error domain for Identity.
 */
static NSString *const kMSIdentityErrorDomain = @"MSIdentityErrorDomain";

/**
 * Error description key for Identity.
 */
static NSString *const kMSIdentityErrorDescriptionKey = @"MSIdentityErrorDescriptionKey";

/**
 * App Center Identity service.
 */
@interface MSIdentity : MSServiceAbstract

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
