#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate <NSObject>

/**
 * A callback that is called when an auth token is received.
 *
 * @param authTokenContext The auth token context.
 * @param authToken The auth token.
 */
- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext didReceiveAuthToken:(NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
