#import <Foundation/Foundation.h>

#import "MSUpdates.h"

/**
 * Updates url query parameter key strings.
 */
static NSString *const kMSUpdtsURLQueryPlatformKey = @"platform";
static NSString *const kMSUpdtsURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSUpdtsURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSUpdtsURLQueryRequestIdKey = @"request_id";

/**
 * Updates url query parameter value strings.
 */
static NSString *const kMSUpdtsURLQueryPlatformValue = @"iOS";

/**
 * Updates custom scheme.
 */
static NSString *const kMSUpdtsDefaultCustomScheme = @"msupdt";

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

@end
