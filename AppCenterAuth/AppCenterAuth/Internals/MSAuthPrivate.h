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
@property(atomic, nullable) MSSignInCompletionHandler signInCompletionHandler;

/**
 * Indicates whether configuration download is in progress.
 */
@property(atomic) bool downloadConfigInProgress;

/**
 * Rest singleton instance.
 */
+ (void)resetSharedInstance;

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
 * Retrieve an updated token without user interaction.
 *
 * @param account The MSALAccount that is used to retrieve an authentication token.
 */
- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account;

/**
 * Retrieve an updated token with user interaction.
 */
- (void)acquireTokenInteractively;

@end

NS_ASSUME_NONNULL_END
