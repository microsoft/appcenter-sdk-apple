#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSTokensResponse;
@class MSStorageIngestion;

typedef void (^MSGetTokenAsyncCompletionHandler)(MSTokensResponse *tokenResponses, NSError *error);

@interface MSTokenExchange : NSObject

/**
 * Get token from token exchange.
 *
 * @param httpIngestion http client.
 * @param completion callback that gets the token.
 *
 */
+ (void)tokenAsync:(MSStorageIngestion *)httpIngestion
           partitions:(NSMutableArray *)partitions
    completionHandler:(MSGetTokenAsyncCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
