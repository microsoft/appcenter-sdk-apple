#import "MSServiceAbstract.h"

@interface MSUpdates : MSServiceAbstract

/**
 * Change The URL that will be used for genereric update related tasks, e.g. fetching the auth token..
 *
 * @param apiUrl The new URL.
 */
+ (void)setApiUrl:(NSString *)apiUrl;

/**
 * Change the base URL that is used to install updates.
 *
 * @param installUrl The new URL.
 */
+ (void)setInstallUrl:(NSString *)installUrl;

@end
