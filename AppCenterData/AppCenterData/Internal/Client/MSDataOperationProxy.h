// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSBaseOptions.h"
#import "MSData.h"
#import "MSDocumentStore.h"
#import "MSTokensResponse.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSCachedTokenCompletionHandler)(MSTokensResponse *_Nullable tokensResponse, NSError *_Nullable error);

/**
 * Class responsible for the core logic between offline and remote calls.
 */
@interface MSDataOperationProxy : NSObject

/**
 * Document store.
 */
@property(nonatomic, nonnull) id<MSDocumentStore> documentStore;

/**
 * Network state helper.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * Initialize a `MSDataOperationProxy` instance.
 *
 * @param documentStore The document store instance.
 * @param reachability Network state helper.
 *
 * @return A new `MSDataOperationProxy` instance.
 */
- (instancetype)initWithDocumentStore:(id<MSDocumentStore>)documentStore reachability:(MS_Reachability *)reachability;

/**
 * Perform an operation for a given partition/document
 * using a combination of the local store and/or CosmosDB remote calls.
 *
 * @param operation The operation (nil - read, CREATE, UPDATE, DELETE). Values are matching the pending operation column in the documents
 * store.
 * @param documentId The document identifier.
 * @param documentType The document type.
 * @param document The document (if the operation is CREATE or UPDATE).
 * @param baseOptions The base options from which to get the device time to live (if specified).
 * @param cachedTokenBlock A block returning the cached token.
 * @param remoteDocumentBlock A block returning the remote document.
 * @param completionHandler The completion handler called ultimately.
 */
- (void)performOperation:(NSString *_Nullable)operation
              documentId:(NSString *)documentId
            documentType:(Class)documentType
                document:(id<MSSerializableDocument> _Nullable)document
             baseOptions:(MSBaseOptions *_Nullable)baseOptions
        cachedTokenBlock:(void (^)(MSCachedTokenCompletionHandler))cachedTokenBlock
     remoteDocumentBlock:(void (^)(MSDocumentWrapperCompletionHandler))remoteDocumentBlock
       completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Performs list for a given partition
 * using a combination of the local store and/or CosmosDB remote calls.
 *
 * @param documentType The documents type.
 * @param partition The partition of the documents.
 * @param baseOptions The base options from which to get the device time to live (if specified).
 * @param cachedTokenBlock A block returning the cached token.
 * @param remoteDocumentBlock A block returning the remote document.
 * @param completionHandler The completion handler called ultimately.
 */
- (void)performListOnDocumentType:(Class)documentType
                        partition:(NSString *)partition
                      baseOptions:(MSBaseOptions *_Nullable)baseOptions
                 cachedTokenBlock:(void (^)(MSCachedTokenCompletionHandler))cachedTokenBlock
              remoteDocumentBlock:(void (^)(MSPaginatedDocumentsCompletionHandler))remoteDocumentBlock
                completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
