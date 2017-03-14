#import <Foundation/Foundation.h>
#import "MSDistribute.h"

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
 * The storage key for ignored release ID.
 */
static NSString *const kMSIgnoredReleaseIdKey = @"MSIgnoredReleaseId";

/**
 * The storage key for request ID.
 */
static NSString *const kMSUpdateTokenRequestIdKey = @"MSUpdateTokenRequestId";

/**
 * The storage key for flag that can determine to clean up update token.
 */
static NSString *const kMSSDKHasLaunchedWithDistribute = @"MSSDKHasLaunchedWithDistribute";

/**
 * The keychain key for update token.
 */
static NSString *const kMSUpdateTokenKey = @"MSUpdateToken";

@interface MSDistribute ()

/**
 * Build the install URL for token request with the given application secret.
 *
 * @param appSecret Application secret.
 *
 * @return The finale install URL to request the token or nil if an error occurred.
 */
- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret;

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
 */
- (void)checkLatestRelease:(NSString *)updateToken;

/**
 * Send a request to get update token.
 */
- (void)requestUpdateToken;

/**
 * Update workflow to make a decision based on release details.
 */
- (void)handleUpdate:(MSReleaseDetails *)details;

/**
 * Show a dialog to ask a user to confirm update for a new release.
 */
- (void)showConfirmationAlert:(MSReleaseDetails *)details;

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
 * Get package hash of the application.
 *
 * @return A package hash string.
 */
- (NSString *)packageHash;

@end
