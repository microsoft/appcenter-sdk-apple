#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreserved-id-macro"
#ifndef __IPHONE_11_0
#define __IPHONE_11_0    110000
#endif
#pragma clang diagnostic pop

#import "MSAlertController.h"
#import "MSUIAppDelegate.h"
#import "MSDistribute.h"
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@class MSReleaseDetails;

/**
 * A day in milliseconds.
 */
static long long const kMSDayInMillisecond =
    24 /* Hours */ * 60 /* Minutes */ * 60 /* Seconds */ * 1000 /* Milliseconds */;

/**
 * Base URL for HTTP Distribute install API calls.
 */
static NSString *const kMSDefaultInstallUrl = @"https://install.mobile.azure.com";

/**
 * Base URL for HTTP Distribute update API calls.
 */
static NSString *const kMSDefaultApiUrl = @"https://api.mobile.azure.com/v0.1";

/**
 * Distribute url query parameter key strings.
 */
static NSString *const kMSURLQueryPlatformKey = @"platform";
static NSString *const kMSURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSURLQueryRequestIdKey = @"request_id";
static NSString *const kMSURLQueryUpdateTokenKey = @"update_token";
static NSString *const kMSURLQueryDistributionGroupIdKey = @"distribution_group_id";
static NSString *const kMSURLQueryEnableUpdateSetupFailureRedirectKey = @"enable_failure_redirect";
static NSString *const kMSURLQueryUpdateSetupFailedKey = @"update_setup_failed";

/**
 * Distribute url query parameter value strings.
 */
static NSString *const kMSURLQueryPlatformValue = @"iOS";

/**
 * Distribute custom URL scheme format.
 */
static NSString *const kMSDefaultCustomSchemeFormat = @"mobilecenter-%@";

/**
 * The storage key for postponed timestamp.
 */
static NSString *const kMSPostponedTimestampKey = @"MSPostponedTimestamp";

/**
 * The storage key for request ID.
 */
static NSString *const kMSUpdateTokenRequestIdKey = @"MSUpdateTokenRequestId";

/**
 * The storage key for flag that can determine to clean up update token.
 */
static NSString *const kMSSDKHasLaunchedWithDistribute = @"MSSDKHasLaunchedWithDistribute";

/**
 * The storage key for last madatory release details.
 */
static NSString *const kMSMandatoryReleaseKey = @"MSMandatoryRelease";

/**
 * The keychain key for update token.
 */
static NSString *const kMSUpdateTokenKey = @"MSUpdateToken";

/**
 * The storage key for distribution group ID.
 */
static NSString *const kMSDistributionGroupIdKey = @"MSDistributionGroupId";

/**
 * The storage key for update setup failure error message.
 */
static NSString *const kMSUpdateSetupFailedMessageKey = @"MSUpdateSetupFailedMessage";

/**
 * The storage key for update setup failure package hash.
 */
static NSString *const kMSUpdateSetupFailedPackageHashKey = @"MSUpdateSetupFailedPackageHash";

@interface MSDistribute ()

/**
 * Current view controller presenting the `SFSafariViewController` if any.
 */
@property(nullable, nonatomic) UIViewController *safariHostingViewController;

/**
 * Current update alert view controller if any.
 */
@property(nonatomic) MSAlertController *updateAlertController;

/**
 * Current release details.
 */
@property(nullable, nonatomic) MSReleaseDetails *releaseDetails;

/**
 * A Distribute delegate that will be called whenever a new release is available for update.
 */
@property(nonatomic, weak) id<MSDistributeDelegate> delegate;

/**
 * Custom application delegate dedicated to Distribute.
 */
@property(nonatomic) id<MSAppDelegate> appDelegate;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
@property(nullable, nonatomic) SFAuthenticationSession *authenticationSession;
#pragma clang diagnostic pop
#endif

/**
 * Returns the singleton instance. Meant for testing/demo apps only.
 *
 * @return the singleton instance of MSDistribute.
 */
+ (instancetype)sharedInstance;

/**
 * Build the install URL for token request with the given application secret.
 *
 * @param appSecret Application secret.
 * @param releaseHash The release hash of the current version.
 *
 * @return The finale install URL to request the token or nil if an error occurred.
 */
- (nullable NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret releaseHash:(NSString *)releaseHash;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
/**
 * Open the given URL using an `SFAuthenticationSession`. Must run on the UI thread! iOS 11 only.
 *
 * @param url URL to open.
 * @param clazz `SFAuthenticationSession` class.
 */
- (void)openURLInAuthenticationSessionWith:(NSURL *)url fromClass:(Class)clazz;
#endif

/**
 * Open the given URL using an `SFSafariViewController`. Must run on the UI thread! iOS 9 and 10 only.
 *
 * @param url URL to open.
 * @param clazz `SFSafariViewController` class.
 */
- (void)openURLInSafariViewControllerWith:(NSURL *)url fromClass:(Class)clazz;

/**
 * Open the given URL using the Safari application. iOS 8.x only.
 *
 * @param url URL to open.
 */
- (void)openURLInSafariApp:(NSURL *)url;

/**
 * Process URL request for the service.
 *
 * @param url  The url with parameters.
 *
 * @return `YES` if the URL is intended for Mobile Center Distribute and the current application, `NO` otherwise.
 */
- (BOOL)openURL:(NSURL *)url;

/**
 * Send a request to get the latest release.
 *
 * @param updateToken The update token stored in keychain. This value can be nil if it is public distribution.
 * @param distributionGroupId The distribution group Id in keychain.
 * @param releaseHash The release hash of the current version.
 */
- (void)checkLatestRelease:(nullable NSString *)updateToken
       distributionGroupId:(NSString *)distributionGroupId
               releaseHash:(NSString *)releaseHash;

/**
 * Send a request to get information for installation.
 *
 * @param releaseHash The release hash of the current version.
 */
- (void)requestInstallInformationWith:(NSString *)releaseHash;

/**
 * Update workflow to make a decision based on release details.
 *
 * @param details Release details to handle.
 *
 * @return `YES` if this update is handled or `NO` otherwise.
 */
- (BOOL)handleUpdate:(MSReleaseDetails *)details;

/**
 * Show a dialog to ask a user to confirm update for a new release.
 */
- (void)showConfirmationAlert:(MSReleaseDetails *)details;

/**
 * Notify custom user action for current release.
 *
 * @param action The action for the release.
 *
 * @discussion This method will be moved to public once Distribute allows to customize the update dialog.
 */
- (void)notifyUpdateAction:(MSUpdateAction)action;

/**
 * Show a dialog to the user in case MSDistribute was disabled while the updates-alert is shown.
 */
- (void)showDistributeDisabledAlert;

/**
 * Check whether release details contain a newer version of release than current version.
 */
- (BOOL)isNewerVersion:(MSReleaseDetails *)details;

/**
 * Check all parameters that determine if it's okay to check for an update.
 *
 * @return BOOL indicating that it's okay to check for updates.
 */
- (BOOL)checkForUpdatesAllowed;

/**
 * Dismiss the Safari hosting view controller.
 */
- (void)dismissEmbeddedSafari;

/**
 * Start update workflow
 */
- (void)startUpdate;

/**
 * Start download for the given details.
 */
- (void)startDownload:(nullable MSReleaseDetails *)details;

/**
 * Close application for update.
 */
- (void)closeApp;

@end

NS_ASSUME_NONNULL_END
