#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSAuthTokenContext;

@protocol MSAuthTokenContextDelegate <NSObject>

/**
 * A callback that is called when an auth token is received.
 *
 * @param authTokenContext The auth token context.
 * @param authToken The auth token.
 * @param isNewUser True if the user has changed, false otherwise.
 */
- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext didReceiveAuthToken:(NSString * _Nullable)authToken forNewUser:(BOOL)isNewUser;

@end

NS_ASSUME_NONNULL_END
