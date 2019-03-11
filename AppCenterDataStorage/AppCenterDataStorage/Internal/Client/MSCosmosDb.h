#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSCosmosDbCompletionHandler)(NSData *data, NSError *error);

@class MSCosmosDbIngestion;
@class MSTokenResult;
@class MSSerializableDocument;

/**
 * This class performs CRUD operation in CosmosDb via an Http client.
 */
@interface MSCosmosDb : NSObject

/**
 * Call CosmosDb Api and perform db actions(read, write, delete, list, etc).
 *
 * @param httpClient Http client to call perform http calls .
 * @param tokenResult Token result object containing token value used to call CosmosDb Api.
 * @param documentId Document Id.
 * @param httpVerb Http verb.
 * @param body Http body.
 * @param completionHandler Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(MSCosmosDbIngestion *)httpClient
          tokenResult:(MSTokenResult *)tokenResult
           documentId:(NSString *)documentId
             httpVerb:(NSString *)httpVerb
                 body:(NSData *)body
    completionHandler:(MSCosmosDbCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
