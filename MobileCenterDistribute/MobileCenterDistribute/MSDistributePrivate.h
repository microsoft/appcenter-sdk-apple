#import <Foundation/Foundation.h>

#import "MSAlertController.h"
#import "MSDistribute.h"

// TODO add nullability here.

@class MSReleaseDetails;

// TODO: Move this to another protocol when delegate is introduced.
typedef NS_ENUM(NSInteger, MSUserUpdateAction) {

  /**
   * Action to trigger update.
   */
  MSUserUpdateActionUpdate,

  /**
   * Action to postpone update.
   */
  MSUserUpdateActionPostpone
};

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
 * Current view controller presenting the `SFSafariViewController` if any.
 */
@property(nonatomic) UIViewController *safariHostingViewController;

/**
 * Current update alert view controller if any.
 */
@property(nonatomic) MSAlertController *updateAlertController;

/**
 * Current release details.
 */
@property(nonatomic) MSReleaseDetails *releaseDetails;

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
- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret releaseHash:(NSString *)releaseHash;

/**
 * Open the given URL using an `SFSafariViewController`. Must run on the UI thread! iOS 9+ only.
 *
 * @param url URL to open.
 * @param clazz `SFSafariViewController` class.
 */
- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class)clazz;

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
 * @discussion Place this method call into app delegate openUrl method.
 */
- (void)openUrl:(NSURL *)url;

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
 * Start download for the given details.
 */
- (void)startDownload:(MSReleaseDetails *)details;

/**
 * Close application for update.
 */
- (void)closeApp;

@end
