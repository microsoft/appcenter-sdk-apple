#import <Foundation/Foundation.h>
#import "MSUpdates.h"

/**
 * Updates url query parameter key strings.
 */
static NSString *const kMSUpdtsURLQueryPlatformKey = @"platform";
static NSString *const kMSUpdtsURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSUpdtsURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSUpdtsURLQueryRequestIdKey = @"request_id";
static NSString *const kMSUpdtsURLQueryUpdateTokenKey = @"update_token";

/**
 * Updates url query parameter value strings.
 */
static NSString *const kMSUpdtsURLQueryPlatformValue = @"iOS";

/**
 * Updates custom scheme.
 */
static NSString *const kMSUpdtsDefaultCustomScheme = @"msupdt";

/**
 * The storage key for ignored release ID.
 */
static NSString *const kMSIgnoredReleaseIdKey = @"MSIgnoredReleaseId";

/**
 * The storage key for request ID.
 */
static NSString *const kMSUpdateTokenRequestIdKey = @"MSUpdateTokenRequestId";

/**
 * The keychain key for update token.
 */
static NSString *const kMSUpdateTokenKey = @"MSUpdateToken";

@interface MSUpdates ()

/**
 * Build the update URL for token request with the given application secret.
 *
 * @param appSecret Application secret.
 * @param error Error to be used if anything goes wrong.
 *
 * @return The finale update URL to request the token or nil if an error occured.
 */
- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret error:(NSError **)error;

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
 * Take a request via custom URL scheme from browser.
 *
 * @param url  The url with parameters.
 */
- (void)openUrl:(NSURL *)url;

/**
 * Send a request to get the latest release.
 */
- (void)checkLatestRelease;

/**
 * Update workflow to make a dicision of update based on release details.
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

@end
