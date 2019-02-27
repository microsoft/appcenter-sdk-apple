#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSGetTokenAsyncCompletionHandler)(NSData *data, NSError *error);

@interface MSTokenExchange : NSObject 

/**
 * Get token from token exchnge.
 *
 * @param httpIngestion http client.
 * @param completion callback that gets the token.
 *
 */
+ (void)tokenAsync:(MSHttpIngestion *)httpIngestion completionHandler:(MSGetTokenAsyncCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
