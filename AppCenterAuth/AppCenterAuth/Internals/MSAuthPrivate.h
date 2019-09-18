// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSALPublicClientApplication.h"
#import "MSAuth.h"
#import "MSAuthConfig.h"
#import "MSAuthConfigIngestion.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSChannelDelegate.h"
#import "MSCustomApplicationDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@class MSALPublicClientApplication;

/**
 * Custom URL Scheme format for MSAL.
 */
static NSString *const kMSMSALCustomSchemeFormat = @"msal%@";

/**
 * The URL Type Role for URL scheme.
 */
static NSString *const kMSURLTypeRoleEditor = @"Editor";

/**
 * Completion handler triggered when complete getting a token.
 *
 * @param userInformation User information for signed in user.
 * @param error Error for sign-in failure.
 */
typedef void (^MSAcquireTokenCompletionHandler)(MSUserInformation *_Nullable userInformation, NSError *_Nullable error);

@interface MSAuth () <MSServiceInternal, MSAuthTokenContextDelegate>

/**
 * The MSAL client for authentication.
 */
@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

/**
 * The configuration for the Auth service.
 */
@property(nonatomic, nullable) MSAuthConfig *authConfig;

/**
 * Base URL of the remote configuration file.
 */
@property(atomic, copy, nullable) NSString *configUrl;

/**
 * Ingestion instance (should not be deallocated).
 */
@property(nonatomic, nullable) MSAuthConfigIngestion *ingestion;

/**
 * Custom application delegate dedicated to Auth.
 */
@property(nonatomic) id<MSCustomApplicationDelegate> appDelegate;

/**
 * Completion handler for sign-in.
 */
@property(atomic, nullable) MSAcquireTokenCompletionHandler signInCompletionHandler;

/**
 * Completion handler for refresh completion.
 */
@property(atomic, nullable) MSAcquireTokenCompletionHandler refreshCompletionHandler;

/**
 * The home account id that should be used for refreshing token after coming back online.
 */
@property(nonatomic, nullable, copy) NSString *accountIdToRefresh;

/**
 * Indicates that there is a pending configuration download
 * and sign in, if called, should wait until configuration is downloaded.
 */
@property(atomic) BOOL signInShouldWaitForConfig;

/**
 * Rest singleton instance.
 */
+ (void)resetSharedInstance;

/**
 * Sign-in to get user information.
 *
 * @param completionHandler Callback that is invoked after sign-in completed. @c `MSSignInCompletionHandler`.
 */
- (void)signInWithCompletionHandler:(MSSignInCompletionHandler _Nullable)completionHandler;

/**
 * Sign out to clear user information.
 */
- (void)signOut;

/**
 * Validate URL Scheme is registered.
 *
 * @param urlScheme Expected URL Scheme for the service.
 *
 * @return `YES` if URL Scheme is registered and valid, otherwise `NO`.
 */
- (BOOL)checkURLSchemeRegistered:(NSString *)urlScheme;

/**
 * Get a file path of auth config.
 *
 * @return The config file path.
 */
- (NSString *)authConfigFilePath;

/**
 * Download auth configuration with an eTag.
 */
- (void)downloadConfigurationWithETag:(nullable NSString *)eTag;

/**
 * Load auth configuration from cache file.
 *
 * @return `YES` if the configuration loaded successfully, otherwise `NO`.
 */
- (BOOL)loadConfigurationFromCache;

/**
 * Config MSAL client.
 */
- (void)configAuthenticationClient;

/**
 * Refreshes token for given accountId.
 */
- (void)refreshTokenForAccountId:(NSString *)accountId withNetworkConnected:(BOOL)networkConnected;

/**
 * Retrieve the account object for the given home account Id from MSAL.
 *
 * @param homeAccountId A home account Id.
 *
 * @return The account object for the given home account Id.
 */
- (MSALAccount *)retrieveAccountWithAccountId:(NSString *)homeAccountId;

/**
 * Remove the current account object from MSAL.
 *
 * @return `YES` if the account is removed successfully, otherwise `NO`.
 */
- (BOOL)removeAccount;

/**
 * Acquires token in background with the given account.
 *
 * @param account The account that is used for acquiring token.
 * @param uiFallback The flag for fallback to interactive sign-in when it fails.
 * @param completionHandlerKeyPath The key path of completion handler to process sign-in or refresh token.
 */
- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account
                                 uiFallback:(BOOL)uiFallback
                keyPathForCompletionHandler:(NSString *)completionHandlerKeyPath;

/**
 * Cancel pending sign-in and refresh token operation.
 *
 * @param errorCode The error code that indicates a reason of cancellation.
 * @param message The message describes a reason of cancellation.
 */
- (void)cancelPendingOperationsWithErrorCode:(NSInteger)errorCode message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
