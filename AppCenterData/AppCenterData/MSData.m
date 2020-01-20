// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSData.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSAuthTokenContext.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSCosmosDb.h"
#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDataPrivate.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentMetadata.h"
#import "MSDocumentMetadataInternal.h"
#import "MSDocumentStore.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSHttpClient.h"
#import "MSHttpUtil.h"
#import "MSPageInternal.h"
#import "MSPaginatedDocumentsInternal.h"
#import "MSPendingOperation.h"
#import "MSReadOptions.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"
#import "MSWriteOptions.h"
#import "MS_Reachability.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Data";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"Data";

/**
 * CosmosDb Documents key (for paginated results).
 */
static NSString *const kMSDocumentsKey = @"Documents";

/**
 * CosmosDb upsert header key.
 */
static NSString *const kMSDocumentUpsertHeaderKey = @"x-ms-documentdb-is-upsert";

/**
 * CosmosDb continuation token header key.
 */
static NSString *const kMSDocumentContinuationTokenHeaderKey = @"x-ms-continuation";

/**
 * Data dispatch queue name.
 */
static char *const kMSDataDispatchQueue = "com.microsoft.appcenter.DataDispatchQueue";

/**
 * Document ID validation pattern.
 */
static NSString *const kMSDocumentIdValidationPattern = @"^[^/\\\\#\\s?]+\\z";

/**
 * Singleton.
 */
static MSData *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSData

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _tokenExchangeUrl = (NSURL *)[NSURL URLWithString:kMSDefaultApiUrl];
    _dispatchQueue = dispatch_queue_create(kMSDataDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _reachability = [MS_Reachability reachabilityForInternetConnection];
    _dataOperationProxy = [[MSDataOperationProxy alloc] initWithDocumentStore:[MSDBDocumentStore new] reachability:_reachability];
    _outgoingPendingOperations = [NSMutableSet new];
  }
  return self;
}

#pragma mark - Public

+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl {
  [[MSData sharedInstance] setTokenExchangeUrl:(NSURL *)[NSURL URLWithString:tokenExchangeUrl]];
}

+ (void)setRemoteOperationDelegate:(nullable id<MSRemoteOperationDelegate>)delegate {
  @synchronized(self) {
    [[MSData sharedInstance] setRemoteOperationDelegate:delegate];
  }
}

+ (void)readDocumentWithID:(NSString *)documentID
              documentType:(Class)documentType
                 partition:(NSString *)partition
         completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] readDocumentWithID:documentID
                                 documentType:documentType
                                    partition:partition
                                  readOptions:nil
                            completionHandler:completionHandler];
}

+ (void)readDocumentWithID:(NSString *)documentID
              documentType:(Class)documentType
                 partition:(NSString *)partition
               readOptions:(MSReadOptions *_Nullable)readOptions
         completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] readDocumentWithID:documentID
                                 documentType:documentType
                                    partition:partition
                                  readOptions:readOptions
                            completionHandler:completionHandler];
}

+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSData sharedInstance] listDocumentsWithType:documentType
                                       partition:partition
                                     readOptions:nil
                               continuationToken:nil
                               completionHandler:completionHandler];
}

+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSData sharedInstance] listDocumentsWithType:documentType
                                       partition:partition
                                     readOptions:readOptions
                               continuationToken:nil
                               completionHandler:completionHandler];
}

+ (void)createDocumentWithID:(NSString *)documentID
                    document:(id<MSSerializableDocument>)document
                   partition:(NSString *)partition
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] createDocumentWithID:documentID
                                       document:document
                                      partition:partition
                                   writeOptions:nil
                              completionHandler:completionHandler];
}

+ (void)createDocumentWithID:(NSString *)documentID
                    document:(id<MSSerializableDocument>)document
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] createDocumentWithID:documentID
                                       document:document
                                      partition:partition
                                   writeOptions:writeOptions
                              completionHandler:completionHandler];
}

+ (void)replaceDocumentWithID:(NSString *)documentID
                     document:(id<MSSerializableDocument>)document
                    partition:(NSString *)partition
            completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] replaceDocumentWithID:documentID
                                        document:document
                                       partition:partition
                                    writeOptions:nil
                               completionHandler:completionHandler];
}

+ (void)replaceDocumentWithID:(NSString *)documentID
                     document:(id<MSSerializableDocument>)document
                    partition:(NSString *)partition
                 writeOptions:(MSWriteOptions *_Nullable)writeOptions
            completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] replaceDocumentWithID:documentID
                                        document:document
                                       partition:partition
                                    writeOptions:writeOptions
                               completionHandler:completionHandler];
}

+ (void)deleteDocumentWithID:(NSString *)documentID
                   partition:(NSString *)partition
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] deleteDocumentWithID:documentID partition:partition writeOptions:nil completionHandler:completionHandler];
}

+ (void)deleteDocumentWithID:(NSString *)documentID
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSData sharedInstance] deleteDocumentWithID:documentID
                                      partition:partition
                                   writeOptions:writeOptions
                              completionHandler:completionHandler];
}

#pragma mark - Static internal

+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            continuationToken:(NSString *_Nullable)continuationToken
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSData sharedInstance] listDocumentsWithType:documentType
                                       partition:partition
                                     readOptions:readOptions
                               continuationToken:continuationToken
                               completionHandler:completionHandler];
}

#pragma mark - MSData Implementation

- (void)replaceDocumentWithID:(NSString *)documentID
                     document:(id<MSSerializableDocument>)document
                    partition:(NSString *)partition
                 writeOptions:(MSWriteOptions *_Nullable)writeOptions
            completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // In the current version we do not support E-tag optimistic concurrency logic and replace will call create.
  [self createOrReplaceDocumentWithID:documentID
                             document:document
                            partition:partition
                         writeOptions:writeOptions
                    additionalHeaders:@{kMSDocumentUpsertHeaderKey : @"true"}
                     pendingOperation:kMSPendingOperationReplace
                    completionHandler:completionHandler];
}

- (void)readDocumentWithID:(NSString *)documentID
              documentType:(Class)documentType
                 partition:(NSString *)partition
               readOptions:(MSReadOptions *_Nullable)readOptions
         completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check preconditions.
    MSDataError *dataError;
    if (![self canBeUsed] || ![self isEnabled]) {
      dataError = [self generateDisabledError:@"read" documentId:documentID];
    } else if (![MSDocumentUtils isSerializableDocument:documentType]) {
      dataError = [self generateInvalidClassError];
    } else if ([self isDocumentIdInvalid:documentID]) {
      dataError = [self generateInvalidDocumentIdError];
    }
    if (dataError) {
      completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:partition documentId:documentID]);
      return;
    }

    // Perform read.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:nil
          documentId:documentID
          documentType:documentType
          document:nil
          baseOptions:readOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClientNoRetrier
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self readFromCosmosDbWithPartition:partition documentId:documentID documentType:documentType completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)createDocumentWithID:(NSString *)documentID
                    document:(id<MSSerializableDocument>)document
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self createOrReplaceDocumentWithID:documentID
                             document:document
                            partition:partition
                         writeOptions:writeOptions
                    additionalHeaders:nil
                     pendingOperation:kMSPendingOperationCreate
                    completionHandler:completionHandler];
}

- (void)deleteDocumentWithID:(NSString *)documentID
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check precondition.
    MSDataError *dataError;
    if (![self canBeUsed] || ![self isEnabled]) {
      dataError = [self generateDisabledError:@"delete" documentId:documentID];
    } else if ([self isDocumentIdInvalid:documentID]) {
      dataError = [self generateInvalidDocumentIdError];
    }
    if (dataError) {
      completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:partition documentId:documentID]);
      return;
    }

    // Perform deletion.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:kMSPendingOperationDelete
          documentId:documentID
          documentType:[MSDictionaryDocument class]
          document:nil
          baseOptions:writeOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClientNoRetrier
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self deleteFromCosmosDbWithPartition:partition documentId:documentID completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)createOrReplaceDocumentWithID:(NSString *)documentID
                             document:(id<MSSerializableDocument>)document
                            partition:(NSString *)partition
                         writeOptions:(MSWriteOptions *_Nullable)writeOptions
                    additionalHeaders:(NSDictionary *)additionalHeaders
                     pendingOperation:(NSString *)pendingOperation
                    completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check the precondition.
    MSDataError *dataError;
    if (![self canBeUsed] || ![self isEnabled]) {
      dataError = [self generateDisabledError:@"create or replace" documentId:documentID];
    } else if (![MSDocumentUtils isSerializableDocument:[document class]]) {
      dataError = [self generateInvalidClassError];
    } else if ([self isDocumentIdInvalid:documentID]) {
      dataError = [self generateInvalidDocumentIdError];
    }
    if (dataError) {
      completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:partition documentId:documentID]);
      return;
    }

    // Perform upsert.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:pendingOperation
          documentId:documentID
          documentType:[document class]
          document:document
          baseOptions:writeOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClientNoRetrier
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self upsertFromCosmosDbWithPartition:partition
                                       documentId:documentID
                                         document:document
                                       httpClient:self.httpClientNoRetrier
                                additionalHeaders:additionalHeaders
                                completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            continuationToken:(nullable NSString *)continuationToken
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {

  @synchronized(self) {

    // Check the preconditions.
    MSDataError *dataError;
    if (![self canBeUsed] || ![self isEnabled]) {
      dataError = [self generateDisabledError:@"list" documentId:nil];
    } else if (![MSDocumentUtils isSerializableDocument:documentType]) {
      dataError = [self generateInvalidClassError];
    } else if (continuationToken && [self.reachability currentReachabilityStatus] == NotReachable) {

      // For offline scenario, if continuation token is provided, then return an error since next page can't be retrieved.
      // Otherwise, (if continuationToken is nil), return the first page.
      dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorNextDocumentPageUnavailable
                                              innerError:nil
                                                 message:(NSString *)kMSACDataErrorNextDocumentPageUnavailableDesc];
    }
    if (dataError) {
      completionHandler([[MSPaginatedDocuments alloc] initWithError:dataError
                                                          partition:partition
                                                       documentType:documentType
                                                  continuationToken:continuationToken]);
      return;
    }

    // Build headers.
    NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
    if (continuationToken) {
      [additionalHeaders setObject:(NSString *)continuationToken forKey:kMSDocumentContinuationTokenHeaderKey];
    }

    // Perform the operation.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy listDocumentsWithType:documentType
          partition:partition
          baseOptions:readOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClientNoRetrier
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSPaginatedDocumentsCompletionHandler handler) {
            [self listFromCosmosDbWithPartition:partition
                                   documentType:documentType
                              additionalHeaders:additionalHeaders
                              completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

#pragma mark - CosmosDB operation implementations

- (void)performCosmosDbOperationWithPartition:(NSString *)partition
                                   documentId:(NSString *_Nullable)documentId
                                   httpMethod:(NSString *)httpMethod
                                   httpClient:(id<MSHttpClientProtocol>)httpClient
                                     document:(id<MSSerializableDocument> _Nullable)document
                            additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                            additionalUrlPath:(NSString *_Nullable)additionalUrlPath
                            completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  [MSTokenExchange
      performDbTokenAsyncOperationWithHttpClient:httpClient
                                tokenExchangeUrl:self.tokenExchangeUrl
                                       appSecret:self.appSecret
                                       partition:partition
                             includeExpiredToken:NO
                                    reachability:self.reachability
                               completionHandler:^(MSTokensResponse *_Nonnull tokensResponse, NSError *_Nonnull error) {
                                 if (error) {
                                   completionHandler(nil, nil, error);
                                   return;
                                 }
                                 [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                                                             tokenResult:(MSTokenResult *)tokensResponse.tokens.firstObject
                                                                              documentId:documentId
                                                                              httpMethod:httpMethod
                                                                                document:document
                                                                       additionalHeaders:additionalHeaders
                                                                       additionalUrlPath:additionalUrlPath
                                                                       completionHandler:^(NSData *_Nullable data,
                                                                                           NSHTTPURLResponse *_Nullable response,
                                                                                           NSError *_Nullable cosmosDbError) {
                                                                         completionHandler(data, response, cosmosDbError);
                                                                       }];
                               }];
}

- (void)readFromCosmosDbWithPartition:(NSString *)partition
                           documentId:(NSString *)documentId
                         documentType:(Class)documentType
                    completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self performCosmosDbOperationWithPartition:partition
                                   documentId:documentId
                                   httpMethod:kMSHttpMethodGet
                                   httpClient:self.httpClientNoRetrier
                                     document:nil
                            additionalHeaders:nil
                            additionalUrlPath:documentId
                            completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                                NSError *_Nullable cosmosDbError) {
                              // If not created.
                              if (response.statusCode != MSHTTPCodesNo200OK) {
                                MSDataError *actualDataError = [MSCosmosDb cosmosDbErrorWithResponse:response
                                                                                     underlyingError:cosmosDbError];
                                MSLogError([MSData logTag],
                                           @"Unable to read document %@ with error: %@. Status code %ld when expecting %ld.", documentId,
                                           [actualDataError localizedDescription], (long)response.statusCode, (long)MSHTTPCodesNo200OK);
                                completionHandler([[MSDocumentWrapper alloc] initWithError:actualDataError
                                                                                 partition:partition
                                                                                documentId:documentId]);
                              }

                              // (Try to) deserialize the incoming document.
                              else {
                                completionHandler([MSDocumentUtils documentWrapperFromData:data
                                                                              documentType:documentType
                                                                                 partition:partition
                                                                                documentId:documentId
                                                                           fromDeviceCache:NO]);
                              }
                            }];
}

- (void)upsertFromCosmosDbWithPartition:(NSString *)partition
                             documentId:(NSString *)documentId
                               document:(id<MSSerializableDocument>)document
                             httpClient:(id<MSHttpClientProtocol>)httpClient
                      additionalHeaders:(NSDictionary *)additionalHeaders
                      completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  // Perform the operation.
  NSDictionary *dic = [MSDocumentUtils documentPayloadWithDocumentId:documentId
                                                           partition:partition
                                                            document:[document serializeToDictionary]];
  if (![NSJSONSerialization isValidJSONObject:dic]) {
    MSDataError *serializationDataError =
        [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed
                                    innerError:nil
                                       message:@"Document dictionary contains values that cannot be serialized."];
    MSLogError([MSData logTag], @"Error serializing data: %@", [serializationDataError localizedDescription]);
    completionHandler([[MSDocumentWrapper alloc] initWithError:serializationDataError partition:partition documentId:documentId]);
    return;
  }
  NSError *serializationError;
  NSData *body = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializationError];
  if (!body || serializationError) {
    MSDataError *serializationDataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed
                                                                      innerError:serializationError
                                                                         message:@"Can't deserialize data."];
    MSLogError([MSData logTag], @"Error serializing data: %@", [serializationDataError localizedDescription]);
    completionHandler([[MSDocumentWrapper alloc] initWithError:serializationDataError partition:partition documentId:documentId]);
    return;
  }
  [self
      performCosmosDbOperationWithPartition:partition
                                 documentId:documentId
                                 httpMethod:kMSHttpMethodPost
                                 httpClient:httpClient
                                   document:(id<MSSerializableDocument>)document
                          additionalHeaders:additionalHeaders
                          additionalUrlPath:nil
                          completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                              NSError *_Nullable cosmosDbError) {
                            // If not created.
                            if (response.statusCode != MSHTTPCodesNo201Created && response.statusCode != MSHTTPCodesNo200OK) {
                              MSDataError *actualDataError = [MSCosmosDb cosmosDbErrorWithResponse:response underlyingError:cosmosDbError];
                              MSLogError([MSData logTag],
                                         @"Unable to create/replace document %@ with error: %@. Status code %ld when expecting %ld or %ld.",
                                         documentId, [actualDataError localizedDescription], (long)response.statusCode,
                                         (long)MSHTTPCodesNo200OK, (long)MSHTTPCodesNo201Created);
                              completionHandler([[MSDocumentWrapper alloc] initWithError:actualDataError
                                                                               partition:partition
                                                                              documentId:documentId]);
                            }

                            // (Try to) deserialize saved document.
                            else {
                              MSLogDebug([MSData logTag], @"Document created/replaced with ID: %@", documentId);
                              completionHandler([MSDocumentUtils documentWrapperFromData:data
                                                                            documentType:[document class]
                                                                               partition:partition
                                                                              documentId:documentId
                                                                         fromDeviceCache:NO]);
                            }
                          }];
}

- (void)listFromCosmosDbWithPartition:(NSString *)partition
                         documentType:(Class)documentType
                    additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                    completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [self performCosmosDbOperationWithPartition:partition
                                   documentId:nil
                                   httpMethod:kMSHttpMethodGet
                                   httpClient:self.httpClientNoRetrier
                                     document:nil
                            additionalHeaders:additionalHeaders
                            additionalUrlPath:nil
                            completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                                NSError *_Nullable cosmosDbError) {
                              // If not OK.
                              if (response.statusCode != MSHTTPCodesNo200OK) {
                                MSDataError *actualDataError = [MSCosmosDb cosmosDbErrorWithResponse:response
                                                                                     underlyingError:cosmosDbError];
                                MSLogError([MSData logTag],
                                           @"Unable to list documents for partition %@: %@. Status code %ld when expecting %ld.", partition,
                                           [actualDataError localizedDescription], (long)response.statusCode, (long)MSHTTPCodesNo200OK);
                                MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:actualDataError
                                                                                                    partition:partition
                                                                                                 documentType:documentType
                                                                                            continuationToken:nil];
                                completionHandler(documents);
                                return;
                              }

                              // Deserialize the list payload and try to get the array of documents.
                              NSError *deserializeError;
                              id jsonPayload = [NSJSONSerialization JSONObjectWithData:(NSData *)data options:0 error:&deserializeError];
                              MSDataError *deserializeDataError = nil;
                              if (!deserializeError && ![MSDocumentUtils isReferenceDictionaryWithKey:jsonPayload
                                                                                                  key:kMSDocumentsKey
                                                                                              keyType:[NSArray class]]) {
                                deserializeDataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed
                                                                                   innerError:deserializeError
                                                                                      message:@"Can't deserialize documents"];
                                if (deserializeDataError) {
                                  MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:deserializeDataError
                                                                                                      partition:partition
                                                                                                   documentType:documentType
                                                                                              continuationToken:nil];
                                  completionHandler(documents);
                                  return;
                                }
                              }

                              // Parse the documents.
                              NSMutableArray<MSDocumentWrapper *> *items = [NSMutableArray new];
                              for (id document in jsonPayload[kMSDocumentsKey]) {

                                // Deserialize document.
                                [items addObject:[MSDocumentUtils documentWrapperFromDictionary:document
                                                                                   documentType:documentType
                                                                                fromDeviceCache:NO]];
                              }

                              // Instantiate the first page and return it.
                              MSPage *page = [[MSPage alloc] initWithItems:items];
                              MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc]
                                       initWithPage:page
                                          partition:partition
                                       documentType:documentType
                                       reachability:self.reachability
                                   deviceTimeToLive:0
                                  continuationToken:[response allHeaderFields][kMSDocumentContinuationTokenHeaderKey]];
                              completionHandler(documents);
                            }];
}

- (void)deleteFromCosmosDbWithPartition:(NSString *)partition
                             documentId:(NSString *)documentId
                      completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self performCosmosDbOperationWithPartition:partition
                                   documentId:documentId
                                   httpMethod:kMSHttpMethodDelete
                                   httpClient:self.httpClientWithRetrier
                                     document:nil
                            additionalHeaders:nil
                            additionalUrlPath:documentId
                            completionHandler:^(NSData *_Nullable __unused responseBody, NSHTTPURLResponse *_Nullable response,
                                                NSError *_Nullable cosmosDbError) {
                              // If not deleted.
                              if (response.statusCode != MSHTTPCodesNo204NoContent) {
                                MSDataError *actualDataError = [MSCosmosDb cosmosDbErrorWithResponse:response
                                                                                     underlyingError:cosmosDbError];
                                MSLogError([MSData logTag],
                                           @"Unable to delete document %@ with error: %@. Status code %ld when expecting %ld.", documentId,
                                           [actualDataError localizedDescription], (long)response.statusCode,
                                           (long)MSHTTPCodesNo204NoContent);
                                completionHandler([[MSDocumentWrapper alloc] initWithError:actualDataError
                                                                                 partition:partition
                                                                                documentId:documentId]);
                              }

                              // Return a non-error document wrapper object to confirm the operation.
                              else {
                                MSLogDebug([MSData logTag], @"Document deleted: %@/%@", partition, documentId);
                                completionHandler([[MSDocumentWrapper alloc] initWithDeserializedValue:nil
                                                                                             jsonValue:nil
                                                                                             partition:partition
                                                                                            documentId:documentId
                                                                                                  eTag:nil
                                                                                       lastUpdatedDate:nil
                                                                                      pendingOperation:nil
                                                                                       fromDeviceCache:NO]);
                              }
                            }];
}

#pragma mark - MSData error utils

- (MSDataError *)generateDisabledError:(NSString *)operation documentId:(NSString *_Nullable)documentId {
  MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDisabledErrorCode
                                                       innerError:nil
                                                          message:(NSString *)kMSACDisabledErrorDesc];
  MSLogError([MSData logTag], @"Not able to perform %@ operation, document ID: %@; error: %@.", operation, documentId,
             [dataError localizedDescription]);
  return dataError;
}

- (MSDataError *)generateInvalidClassError {
  MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorInvalidClassCode
                                                       innerError:nil
                                                          message:(NSString *)kMSACDataInvalidClassDesc];
  MSLogError([MSData logTag], @"Not able to validate document deserialization precondition: %@.", [dataError localizedDescription]);
  return dataError;
}

- (BOOL)isDocumentIdInvalid:(NSString *)documentId {
  if (!documentId) {
    return YES;
  }
  NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:kMSDocumentIdValidationPattern options:0 error:nil];
  NSUInteger matchCount = [expr numberOfMatchesInString:documentId options:0 range:NSMakeRange(0, documentId.length)];
  return matchCount == 0;
}

- (MSDataError *)generateInvalidDocumentIdError {
  MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorDocumentIdInvalid
                                                       innerError:nil
                                                          message:(NSString *)kMSACDataErrorDocumentIdInvalidDesc];
  MSLogError([MSData logTag], @"%@", kMSACDataErrorDocumentIdInvalidDesc);
  return dataError;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSData alloc] init];
    }
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {

  // Resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  if (appSecret) {
  }
  MSLogVerbose([MSData logTag], @"Started Data service.");
}

- (void)enabledNotifications {
  // Listen to network events.
  [MS_NOTIFICATION_CENTER addObserver:self selector:@selector(networkStateChanged:) name:kMSReachabilityChangedNotification object:nil];
}

- (void)disableNotificaitons {
  [MS_NOTIFICATION_CENTER removeObserver:self];
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterData";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  [self.httpClientNoRetrier setEnabled:isEnabled];
  [self.httpClientWithRetrier setEnabled:isEnabled];
  if (isEnabled) {
    [[MSAuthTokenContext sharedInstance] addDelegate:self];
    [self enabledNotifications];

  } else {
    [self disableNotificaitons];
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [MSTokenExchange removeAllCachedTokens];
    [self.dataOperationProxy.documentStore resetDatabase];
    [self.outgoingPendingOperations removeAllObjects];
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext didUpdateAccountId:(NSString *)accountId {

  // If user logs in.
  if (accountId) {
    [self.dataOperationProxy.documentStore createUserStorageWithAccountId:accountId];
  } else {
    // If user logs out.
    [MSTokenExchange removeAllCachedTokens];

    // Delete all the data (user and read-only).
    [self.dataOperationProxy.documentStore resetDatabase];
  }
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)__unused notification {

  // Network status change event.
  if ([[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
    MSLogInfo([MSData logTag], @"Network connection is off.");
  } else {
    MSLogInfo([MSData logTag], @"Network connection is on.");
    [self processPendingOperations];
  }
}

- (void)processPendingOperations {

  // Only process pending operations when auth context is available.
  if ([[MSAuthTokenContext sharedInstance] authToken] == nil) {
    return;
  }

  // Process pending operations.
  @synchronized(self) {
    [MSTokenExchange
        performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClientNoRetrier
                                  tokenExchangeUrl:self.tokenExchangeUrl
                                         appSecret:self.appSecret
                                         partition:kMSDataUserDocumentsPartition
                               includeExpiredToken:NO
                                      reachability:self.reachability
                                 completionHandler:^(MSTokensResponse *_Nonnull tokenResponses, NSError *_Nonnull error) {
                                   if (error) {
                                     MSLogWarning([MSData logTag], @"Cannot read from local storage because there is no "
                                                                   @"account ID cached and failed to retrieve token.");
                                     return;
                                   }

                                   // Run the operation in a dispatch queue.
                                   dispatch_async(self.dispatchQueue, ^{
                                     // Get pending operations.
                                     NSArray<MSPendingOperation *> *pendingOperations =
                                         [self.dataOperationProxy.documentStore pendingOperationsWithToken:tokenResponses.tokens[0]];

                                     // Process pending operations.
                                     for (MSPendingOperation *operation in pendingOperations) {

                                       // Get outgoing operation id.
                                       __block NSString *operationId =
                                           [MSDocumentUtils outgoingOperationIdWithPartition:kMSDataUserDocumentsPartition
                                                                                  documentId:operation.documentId];

                                       // If the operation is already being processed, skip it.
                                       if ([self.outgoingPendingOperations containsObject:operationId]) {
                                         continue;
                                       }

                                       // Add current operation as pending.
                                       [self.outgoingPendingOperations addObject:operationId];

                                       // Create or Replace operation.
                                       if ([operation.operation isEqualToString:kMSPendingOperationCreate] ||
                                           [operation.operation isEqualToString:kMSPendingOperationReplace]) {

                                         // Get the document as dictionary.
                                         MSDictionaryDocument *dictionaryDocument =
                                             [[MSDictionaryDocument alloc] initFromDictionary:operation.document];

                                         // Get header.
                                         NSDictionary *additionalHeader = [operation.operation isEqualToString:kMSPendingOperationReplace]
                                                                              ? @{kMSDocumentUpsertHeaderKey : @"true"}
                                                                              : nil;

                                         // Perform CosmosDb operation.
                                         [self
                                             upsertFromCosmosDbWithPartition:kMSDataUserDocumentsPartition
                                                                  documentId:operation.documentId
                                                                    document:dictionaryDocument
                                                                  httpClient:self.httpClientWithRetrier
                                                           additionalHeaders:additionalHeader
                                                           completionHandler:^(MSDocumentWrapper *_Nonnull documentWrapper) {
                                                             [self
                                                                 synchronizeLocalCacheWithCosmosDbWithToken:tokenResponses.tokens[0]
                                                                                                 documentId:(NSString *)operation.documentId
                                                                                            documentWrapper:documentWrapper
                                                                                           pendingOperation:operation.operation
                                                                                    operationExpirationTime:(NSInteger)
                                                                                                                operation.expirationTime];

                                                             // Remove the pending operation id.
                                                             [self.outgoingPendingOperations removeObject:operationId];
                                                             return;
                                                           }];
                                       } else if ([operation.operation isEqualToString:kMSPendingOperationDelete]) {

                                         // Perform delete operation.
                                         [self
                                             deleteFromCosmosDbWithPartition:kMSDataUserDocumentsPartition
                                                                  documentId:operation.documentId
                                                           completionHandler:^(MSDocumentWrapper *_Nonnull documentWrapper) {
                                                             [self
                                                                 synchronizeLocalCacheWithCosmosDbWithToken:tokenResponses.tokens[0]
                                                                                                 documentId:(NSString *)operation.documentId
                                                                                            documentWrapper:documentWrapper
                                                                                           pendingOperation:operation.operation
                                                                                    operationExpirationTime:kMSDataTimeToLiveNoCache];

                                                             // Remove the pending operation id.
                                                             [self.outgoingPendingOperations removeObject:operationId];
                                                             return;
                                                           }];
                                       } else {
                                         MSLogError([MSData logTag], @"Pending operation '%@' is not supported", operation.operation);
                                       }
                                     }
                                     return;
                                   });
                                 }];
  }
}

- (void)synchronizeLocalCacheWithCosmosDbWithToken:(MSTokenResult *)token
                                        documentId:(NSString *)documentId
                                   documentWrapper:(MSDocumentWrapper *)documentWrapper
                                  pendingOperation:(NSString *)pendingOperation
                           operationExpirationTime:(NSInteger)operationExpirationTime {

  // Check if expired.
  BOOL isExpired = [MSPendingOperation isExpiredWithExpirationTime:operationExpirationTime];
  BOOL shouldDeleteLocalCache = YES;
  MSDocumentMetadata *documentMetadata = nil;

  // Create and Replace operations.
  if (!documentWrapper.error && ![pendingOperation isEqualToString:kMSPendingOperationDelete]) {

    // If not expired, update the local cache. otherwise, remove from the local cache.
    // The operation is passes as nil in order to clear the value in `pending_operation` column.
    if (!isExpired) {
      [self.dataOperationProxy.documentStore upsertWithToken:token
                                             documentWrapper:documentWrapper
                                                   operation:nil
                                              expirationTime:operationExpirationTime];
      shouldDeleteLocalCache = NO;
    }

    documentMetadata = [[MSDocumentMetadata alloc] initWithPartition:documentWrapper.partition
                                                          documentId:documentWrapper.documentId
                                                                eTag:documentWrapper.eTag];
  } else if (documentWrapper.error.code == MSHTTPCodesNo404NotFound || documentWrapper.error.code == MSHTTPCodesNo409Conflict) {
    MSLogError([MSData logTag], @"Failed to call Cosmos with operation: %@. Remote operation failed with error code: %ld", pendingOperation,
               (long)documentWrapper.error);
  } else if (documentWrapper.error) {
    MSLogError([MSData logTag], @"Failed to call Cosmos with operation:%@ API: %@", pendingOperation,
               [documentWrapper.error localizedDescription]);
  }

  // Delete the document form the local cache.
  if (shouldDeleteLocalCache) {
    [self.dataOperationProxy.documentStore deleteWithToken:token documentId:documentId];
  }

  // If the Remote operation is set
  id<MSRemoteOperationDelegate> strongDelegate;
  @synchronized(self) {
    strongDelegate = self.remoteOperationDelegate;
    if ([strongDelegate respondsToSelector:@selector(data:didCompleteRemoteOperation:forDocumentMetadata:withError:)]) {
      [strongDelegate data:self
          didCompleteRemoteOperation:pendingOperation
                 forDocumentMetadata:documentMetadata
                           withError:documentWrapper.error];
    }
  }
}

@end
