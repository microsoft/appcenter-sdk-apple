#import "MSUpdates.h"
#import <Foundation/Foundation.h>

/**
 * Updates url query parameter key strings.
 */
static NSString *const kMSUpdtURLQueryPlatformKey = @"platform";
static NSString *const kMSUpdtURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSUpdtURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSUpdtURLQueryRequestIdKey = @"request_id";

/**
 * Updates url query parameter value strings.
 */
static NSString *const kMSUpdtURLQueryPlatformValue = @"iOS";

/**
 * Updates custom scheme.
 */
static NSString *const kMSUpdtDefaultCustomScheme = @"msupdt";

@interface MSUpdates ()

/**
 * Build the update URL for token request with the given application secret. Throws exceptions if anything goes wrong.
 *
 * @param appSecret Application secret.
 *
 * @return The finale update URL to request the token.
 */
- (NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret;

/**
 * Open the given URL using an `SFSafariViewController`. iOS 9+ only.
 *
 * @param url URL to open.
 * @param clazz SFSafariViewController` class.
 */
- (void)openURLInEmbeddedSafari:(NSURL *)url fromClass:(Class)clazz;

/**
 * Open the given URL using the Safari application. iOS 8.x only.
 *
 * @param url URL to open.
 */
- (void)openURLInSafariApp:(NSURL *)url;

@end
