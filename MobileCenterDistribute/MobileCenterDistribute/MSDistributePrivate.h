#import <Foundation/Foundation.h>

#import "MSAlertController.h"
#import "MSAppDelegate.h"
#import "MSDistribute.h"

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

@interface MSDistribute ()

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
 * @param updateToken The update token stored in keychain.
 * @param releaseHash The release hash of the current version.
 */
- (void)checkLatestRelease:(NSString *)updateToken releaseHash:(NSString *)releaseHash;

/**
 * Send a request to get update token.
 *
 * @param releaseHash The release hash of the current version.
 */
- (void)requestUpdateToken:(NSString *)releaseHash;

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
