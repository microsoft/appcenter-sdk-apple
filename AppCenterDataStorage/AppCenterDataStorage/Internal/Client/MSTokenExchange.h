#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSTokensResponse;
typedef void (^MSGetTokenAsyncCompletionHandler)(MSTokensResponse *tokenResponses, NSError *error);

@class MSStorageIngestion;

@interface MSTokenExchange : NSObject

/**
 * Get token from token exchange.
 *
 * @param httpIngestion http client.
 * @param completion callback that gets the token.
 *
 */
+ (void)tokenAsync:(MSStorageIngestion *)httpIngestion
           partitions:(NSArray *)partitions
    completionHandler:(MSGetTokenAsyncCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
