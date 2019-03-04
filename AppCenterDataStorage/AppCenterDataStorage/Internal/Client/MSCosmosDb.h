#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSCosmosDbCompletionHandler)(NSData *data, NSError *error);

@class MSCosmosDbIngestion;
@class MSTokenResult;

@interface MSCosmosDb : NSObject

/**
 * Call CosmosDb Api.
 *
 * @param httpIngestion Http client.
 * @param tokenResult Token result.
 * @param documentId Document Id.
 * @param httpVerb Http verb.
 * @param body Http body.
 * @param completion Completion callback.
 *
 */
+ (void)cosmosDbAsync:(MSCosmosDbIngestion *)httpIngestion
          tokenResult:(MSTokenResult *)tokenResult
           documentId:(NSString *)documentId
             httpVerb:(NSString *)httpVerb
                 body:(NSString *)body
    completionHandler:(MSCosmosDbCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
