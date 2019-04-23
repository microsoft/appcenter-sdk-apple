// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataStore.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSAuthTokenContext.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSCosmosDb.h"
#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentStore.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSHttpClient.h"
#import "MSHttpUtil.h"
#import "MSPaginatedDocuments.h"
#import "MSPendingOperation.h"
#import "MSReadOptions.h"
#import "MSServiceAbstractProtected.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"
#import "MSUserInformation.h"
#import "MSWriteOptions.h"
#import "MS_Reachability.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"DataStorage";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"DataStorage";

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
 * Data Store dispatch queue name.
 */
static char *const kMSDataStoreDispatchQueue = "com.microsoft.appcenter.DataStoreDispatchQueue";

/**
 * Singleton.
 */
static MSDataStore *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSDataStore

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _tokenExchangeUrl = (NSURL *)[NSURL URLWithString:kMSDefaultApiUrl];
    _dispatchQueue = dispatch_queue_create(kMSDataStoreDispatchQueue, DISPATCH_QUEUE_SERIAL);
    _reachability = [MS_Reachability reachabilityForInternetConnection];
    _dataOperationProxy = [[MSDataOperationProxy alloc] initWithDocumentStore:[MSDBDocumentStore new] reachability:_reachability];
  }
  return self;
}

#pragma mark - Public

+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl {
  [[MSDataStore sharedInstance] setTokenExchangeUrl:(NSURL *)[NSURL URLWithString:tokenExchangeUrl]];
}

+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] readWithPartition:partition
                                       documentId:documentId
                                     documentType:documentType
                                      readOptions:nil
                                completionHandler:completionHandler];
}

+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] readWithPartition:partition
                                       documentId:documentId
                                     documentType:documentType
                                      readOptions:readOptions
                                completionHandler:completionHandler];
}

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] listWithPartition:partition
                                     documentType:documentType
                                continuationToken:nil
                                completionHandler:completionHandler];
}

+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] createWithPartition:partition
                                         documentId:documentId
                                           document:document
                                       writeOptions:nil
                                  completionHandler:completionHandler];
}

+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] createWithPartition:partition
                                         documentId:documentId
                                           document:document
                                       writeOptions:writeOptions
                                  completionHandler:completionHandler];
}

+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] replaceWithPartition:partition
                                          documentId:documentId
                                            document:document
                                        writeOptions:nil
                                   completionHandler:completionHandler];
}

+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] replaceWithPartition:partition
                                          documentId:documentId
                                            document:document
                                        writeOptions:writeOptions
                                   completionHandler:completionHandler];
}

+ (void)deleteWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] deleteWithPartition:partition documentId:documentId writeOptions:nil completionHandler:completionHandler];
}

+ (void)deleteWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] deleteWithPartition:partition
                                         documentId:documentId
                                       writeOptions:writeOptions
                                  completionHandler:completionHandler];
}

#pragma mark - Static internal

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        continuationToken:(NSString *_Nullable)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] listWithPartition:partition
                                     documentType:documentType
                                continuationToken:continuationToken
                                completionHandler:completionHandler];
}

#pragma mark - MSDataStore Implementation

- (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // In the current version we do not support E-tag optimistic concurrency logic and replace will call create.
  [self createOrReplaceWithPartition:partition
                          documentId:documentId
                            document:document
                        writeOptions:writeOptions
                   additionalHeaders:@{kMSDocumentUpsertHeaderKey : @"true"}
                    pendingOperation:kMSPendingOperationReplace
                   completionHandler:completionHandler];
}

- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check preconditions.
    NSError *error;
    if (![self canBeUsed] || ![self isEnabled]) {
      error = [self generateDisabledError:@"read" documentId:documentId];
    } else if (![MSDocumentUtils isSerializableDocument:documentType]) {
      error = [self generateInvalidClassError];
    }
    if (error) {
      completionHandler([[MSDocumentWrapper alloc] initWithError:error documentId:documentId]);
      return;
    }

    // Perform read.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:nil
          documentId:documentId
          documentType:documentType
          document:nil
          baseOptions:readOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self readFromCosmosDbWithPartition:partition documentId:documentId documentType:documentType completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self createOrReplaceWithPartition:partition
                          documentId:documentId
                            document:document
                        writeOptions:writeOptions
                   additionalHeaders:nil
                    pendingOperation:kMSPendingOperationCreate
                   completionHandler:completionHandler];
}

- (void)deleteWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check precondition.
    if (![self canBeUsed] || ![self isEnabled]) {
      NSError *error = [self generateDisabledError:@"delete" documentId:documentId];
      completionHandler([[MSDocumentWrapper alloc] initWithError:error documentId:documentId]);
      return;
    }

    // Perform deletion.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:kMSPendingOperationDelete
          documentId:documentId
          documentType:[MSDictionaryDocument class]
          document:nil
          baseOptions:writeOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self deleteFromCosmosDbWithPartition:partition documentId:documentId completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)createOrReplaceWithPartition:(NSString *)partition
                          documentId:(NSString *)documentId
                            document:(id<MSSerializableDocument>)document
                        writeOptions:(MSWriteOptions *_Nullable)writeOptions
                   additionalHeaders:(NSDictionary *)additionalHeaders
                    pendingOperation:(NSString *)pendingOperation
                   completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  @synchronized(self) {

    // Check the precondition.
    if (![self canBeUsed] || ![self isEnabled]) {
      NSError *error = [self generateDisabledError:@"create or replace" documentId:documentId];
      completionHandler([[MSDocumentWrapper alloc] initWithError:error documentId:documentId]);
      return;
    }

    // Perform upsert.
    dispatch_async(self.dispatchQueue, ^{
      [self.dataOperationProxy performOperation:pendingOperation
          documentId:documentId
          documentType:[document class]
          document:document
          baseOptions:writeOptions
          cachedTokenBlock:^(MSCachedTokenCompletionHandler handler) {
            [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
                                                       tokenExchangeUrl:self.tokenExchangeUrl
                                                              appSecret:self.appSecret
                                                              partition:partition
                                                    includeExpiredToken:YES
                                                           reachability:self.reachability
                                                      completionHandler:handler];
          }
          remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler handler) {
            [self upsertFromCosmosDbWithPartition:partition
                                       documentId:documentId
                                         document:document
                                additionalHeaders:additionalHeaders
                                completionHandler:handler];
          }
          completionHandler:completionHandler];
    });
  }
}

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        continuationToken:(nullable NSString *)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {

  @synchronized(self) {

    // Check the preconditions.
    NSError *error;
    if (![self canBeUsed] || ![self isEnabled]) {
      error = [self generateDisabledError:@"list" documentId:nil];
    } else if (![MSDocumentUtils isSerializableDocument:documentType]) {
      error = [self generateInvalidClassError];
    }
    if (error) {
      completionHandler([[MSPaginatedDocuments alloc] initWithError:[[MSDataSourceError alloc] initWithError:error]
                                                          partition:partition
                                                       documentType:documentType]);
      return;
    }

    // Build headers.
    NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
    if (continuationToken) {
      [additionalHeaders setObject:(NSString *)continuationToken forKey:kMSDocumentContinuationTokenHeaderKey];
    }

    // Perform the operation.
    dispatch_async(self.dispatchQueue, ^{
      [self performCosmosDbOperationWithPartition:partition
                                       documentId:nil
                                       httpMethod:kMSHttpMethodGet
                                         document:nil
                                additionalHeaders:additionalHeaders
                                additionalUrlPath:nil
                                completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                                    NSError *_Nullable cosmosDbError) {
                                  // If not OK.
                                  if (response.statusCode != MSHTTPCodesNo200OK) {
                                    NSError *actualError = [MSCosmosDb cosmosDbErrorWithResponse:response underlyingError:cosmosDbError];
                                    MSLogError([MSDataStore logTag],
                                               @"Unable to list documents for partition %@: %@. Status code %ld when expecting %ld.",
                                               partition, [actualError localizedDescription], (long)response.statusCode,
                                               (long)MSHTTPCodesNo200OK);
                                    MSDataSourceError *dataSourceCosmosDbError = [[MSDataSourceError alloc] initWithError:actualError];
                                    MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:dataSourceCosmosDbError
                                                                                                        partition:partition
                                                                                                     documentType:documentType];
                                    completionHandler(documents);
                                    return;
                                  }

                                  // Deserialize the list payload and try to get the array of documents.
                                  NSError *deserializeError;
                                  id jsonPayload = [NSJSONSerialization JSONObjectWithData:(NSData *)data
                                                                                   options:0
                                                                                     error:&deserializeError];
                                  if (!deserializeError && ![MSDocumentUtils isReferenceDictionaryWithKey:jsonPayload
                                                                                                      key:kMSDocumentsKey
                                                                                                  keyType:[NSArray class]]) {
                                    deserializeError =
                                        [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                                   code:MSACDataStoreErrorJSONSerializationFailed
                                                               userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize documents"}];
                                  }
                                  if (deserializeError) {
                                    MSDataSourceError *dataSourceDeserializeError =
                                        [[MSDataSourceError alloc] initWithError:deserializeError];
                                    MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:dataSourceDeserializeError
                                                                                                        partition:partition
                                                                                                     documentType:documentType];
                                    completionHandler(documents);
                                    return;
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
                                      continuationToken:[response allHeaderFields][kMSDocumentContinuationTokenHeaderKey]];
                                  completionHandler(documents);
                                }];
    });
  }
}

#pragma mark - CosmosDB operation implementations

- (void)performCosmosDbOperationWithPartition:(NSString *)partition
                                   documentId:(NSString *_Nullable)documentId
                                   httpMethod:(NSString *)httpMethod
                                     document:(id<MSSerializableDocument> _Nullable)document
                            additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                            additionalUrlPath:(NSString *_Nullable)additionalUrlPath
                            completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  [MSTokenExchange
      performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
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

                                 [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:(MSHttpClient * _Nonnull) self.httpClient
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
                                     document:nil
                            additionalHeaders:nil
                            additionalUrlPath:documentId
                            completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                                NSError *_Nullable cosmosDbError) {
                              // If not created.
                              if (response.statusCode != MSHTTPCodesNo200OK) {
                                NSError *actualError = [MSCosmosDb cosmosDbErrorWithResponse:response underlyingError:cosmosDbError];
                                MSLogError([MSDataStore logTag],
                                           @"Unable to read document %@ with error: %@. Status code %ld when expecting %ld.", documentId,
                                           [actualError localizedDescription], (long)response.statusCode, (long)MSHTTPCodesNo200OK);
                                completionHandler([[MSDocumentWrapper alloc] initWithError:actualError documentId:documentId]);
                              }

                              // (Try to) deserialize the incoming document.
                              else {
                                completionHandler([MSDocumentUtils documentWrapperFromData:data
                                                                              documentType:documentType
                                                                           fromDeviceCache:NO]);
                              }
                            }];
}

- (void)upsertFromCosmosDbWithPartition:(NSString *)partition
                             documentId:(NSString *)documentId
                               document:(id<MSSerializableDocument>)document
                      additionalHeaders:(NSDictionary *)additionalHeaders
                      completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  // Perform the operation.
  NSError *serializationError;
  NSDictionary *dic = [MSDocumentUtils documentPayloadWithDocumentId:documentId
                                                           partition:partition
                                                            document:[document serializeToDictionary]];
  if (![NSJSONSerialization isValidJSONObject:dic]) {
    serializationError =
        [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                   code:MSACDataStoreErrorJSONSerializationFailed
                               userInfo:@{NSLocalizedDescriptionKey : @"Document dictionary contains values that cannot be serialized."}];
    MSLogError([MSDataStore logTag], @"Error serializing data: %@", [serializationError localizedDescription]);
    completionHandler([[MSDocumentWrapper alloc] initWithError:serializationError documentId:documentId]);
    return;
  }
  NSData *body = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializationError];
  if (!body || serializationError) {
    MSLogError([MSDataStore logTag], @"Error serializing data: %@", [serializationError localizedDescription]);
    completionHandler([[MSDocumentWrapper alloc] initWithError:serializationError documentId:documentId]);
    return;
  }
  [self
      performCosmosDbOperationWithPartition:partition
                                 documentId:documentId
                                 httpMethod:kMSHttpMethodPost
                                   document:(id<MSSerializableDocument>)document
                          additionalHeaders:additionalHeaders
                          additionalUrlPath:nil
                          completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response,
                                              NSError *_Nullable cosmosDbError) {
                            // If not created.
                            if (response.statusCode != MSHTTPCodesNo201Created && response.statusCode != MSHTTPCodesNo200OK) {
                              NSError *actualError = [MSCosmosDb cosmosDbErrorWithResponse:response underlyingError:cosmosDbError];
                              MSLogError([MSDataStore logTag],
                                         @"Unable to create/replace document %@ with error: %@. Status code %ld when expecting %ld or %ld.",
                                         documentId, [actualError localizedDescription], (long)response.statusCode,
                                         (long)MSHTTPCodesNo200OK, (long)MSHTTPCodesNo201Created);
                              completionHandler([[MSDocumentWrapper alloc] initWithError:actualError documentId:documentId]);
                            }

                            // (Try to) deserialize saved document.
                            else {
                              MSLogDebug([MSDataStore logTag], @"Document created/replaced with ID: %@", documentId);
                              completionHandler([MSDocumentUtils documentWrapperFromData:data
                                                                            documentType:[document class]
                                                                         fromDeviceCache:NO]);
                            }
                          }];
}

- (void)deleteFromCosmosDbWithPartition:(NSString *)partition
                             documentId:(NSString *)documentId
                      completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self performCosmosDbOperationWithPartition:partition
                                   documentId:documentId
                                   httpMethod:kMSHttpMethodDelete
                                     document:nil
                            additionalHeaders:nil
                            additionalUrlPath:documentId
                            completionHandler:^(NSData *_Nullable __unused responseBody, NSHTTPURLResponse *_Nullable response,
                                                NSError *_Nullable cosmosDbError) {
                              // If not deleted.
                              if (response.statusCode != MSHTTPCodesNo204NoContent) {
                                NSError *actualError = [MSCosmosDb cosmosDbErrorWithResponse:response underlyingError:cosmosDbError];
                                MSLogError([MSDataStore logTag],
                                           @"Unable to delete document %@ with error: %@. Status code %ld when expecting %ld.", documentId,
                                           [actualError localizedDescription], (long)response.statusCode, (long)MSHTTPCodesNo204NoContent);
                                completionHandler([[MSDocumentWrapper alloc] initWithError:actualError documentId:documentId]);
                              }

                              // Return a non-error document wrapper object to confirm the operation.
                              else {
                                MSLogDebug([MSDataStore logTag], @"Document deleted: %@/%@", partition, documentId);
                                completionHandler([[MSDocumentWrapper alloc] initWithDeserializedValue:nil
                                                                                             jsonValue:nil
                                                                                             partition:partition
                                                                                            documentId:documentId
                                                                                                  eTag:nil
                                                                                       lastUpdatedDate:nil
                                                                                      pendingOperation:nil
                                                                                                 error:nil
                                                                                       fromDeviceCache:NO]);
                              }
                            }];
}

#pragma mark - MSDataStore error utils

- (NSError *)generateDisabledError:(NSString *)operation documentId:(NSString *_Nullable)documentId {
  NSError *error = [[NSError alloc] initWithDomain:kMSACErrorDomain
                                              code:MSACDisabledErrorCode
                                          userInfo:@{NSLocalizedDescriptionKey : kMSACDisabledErrorDesc}];
  MSLogError([MSDataStore logTag], @"Not able to perform %@ operation, document ID: %@; error: %@", operation, documentId,
             [error localizedDescription]);
  return error;
}

- (NSError *)generateInvalidClassError {
  NSError *error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                              code:MSACDataStoreInvalidClassCode
                                          userInfo:@{NSLocalizedDescriptionKey : kMSACDataStoreInvalidClassDesc}];
  MSLogError([MSDataStore logTag], @"Not able to validate document deserialization precondition: %@", [error localizedDescription]);
  return error;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSDataStore alloc] init];
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
    self.httpClient = [MSHttpClient new];
  }
  MSLogVerbose([MSDataStore logTag], @"Started Data Storage service.");
}

- (void)enabledNotifications {
  // Listen to network events.
  [MS_NOTIFICATION_CENTER addObserver:self
                             selector:@selector(networkStateChanged:)
                                 name:kMSReachabilityChangedNotification
                               object:nil];
}

- (void)disableNotificaitons {
  [MS_NOTIFICATION_CENTER removeObserver:self];
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterDataStorage";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  [self.httpClient setEnabled:isEnabled];
  if (isEnabled) {
    [[MSAuthTokenContext sharedInstance] addDelegate:self];
    [self enabledNotifications];

  } else {
    [self disableNotificaitons];
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [MSTokenExchange removeAllCachedTokens];
    [self.dataOperationProxy.documentStore deleteAllTables];
    [self.outgoingPendingOperations removeAllObjects];
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext didUpdateUserInformation:(MSUserInformation *)userInfomation {

  // If user logs in.
  if (userInfomation && userInfomation) {
    [self.dataOperationProxy.documentStore createUserStorageWithAccountId:userInfomation.accountId];
  } else {
    // If user logs out.
    [MSTokenExchange removeAllCachedTokens];

    // Delete all the data (user and read-only).
    [self.dataOperationProxy.documentStore deleteAllTables];
  }
}

#pragma mark - Reachability

- (void)networkStateChanged:(NSNotificationCenter *)__unused notification {

  // Network status change event.
  if ([[MS_Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
    MSLogInfo([MSDataStore logTag], @"Network connection is off.");
  } else {
    MSLogInfo([MSDataStore logTag], @"Network connection is on.");
    [self processPendingOperations];
  }
}

- (void)processPendingOperations {
  @synchronized(self) {
    [MSTokenExchange
        performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
                                  tokenExchangeUrl:self.tokenExchangeUrl
                                         appSecret:self.appSecret
                                         partition:kMSDataStoreUserDocumentsPartition
                               includeExpiredToken:NO
                                      reachability:self.reachability
                                 completionHandler:^(MSTokensResponse *_Nonnull tokenResponses, NSError *_Nonnull error) {
                                   if (error) {
                                     MSLogError([MSDataStore logTag], @"Cannot read from local storage because there is no "
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
                                           [MSDocumentUtils outgoingOperationIdWithPartition:kMSDataStoreUserDocumentsPartition
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
                                             upsertFromCosmosDbWithPartition:kMSDataStoreUserDocumentsPartition
                                                                  documentId:operation.documentId
                                                                    document:dictionaryDocument
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
                                             deleteFromCosmosDbWithPartition:kMSDataStoreUserDocumentsPartition
                                                                  documentId:operation.documentId
                                                           completionHandler:^(MSDocumentWrapper *_Nonnull documentWrapper) {
                                                             [self
                                                                 synchronizeLocalCacheWithCosmosDbWithToken:tokenResponses.tokens[0]
                                                                                                 documentId:(NSString *)operation.documentId
                                                                                            documentWrapper:documentWrapper
                                                                                           pendingOperation:operation.operation
                                                                                    operationExpirationTime:kMSDataStoreTimeToLiveNoCache];

                                                             // Remove the pending operation id.
                                                             [self.outgoingPendingOperations removeObject:operationId];
                                                             return;
                                                           }];
                                       } else {
                                         MSLogError([MSDataStore logTag], @"Pending operation '%@' is not supported", operation.operation);
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
  } else if (documentWrapper.error.errorCode == MSHTTPCodesNo404NotFound || documentWrapper.error.errorCode == MSHTTPCodesNo409Conflict) {
    MSLogError([MSDataStore logTag], @"Failed to call Cosmos with operation: %@. Remote operation failed with error code: %ld",
               pendingOperation, (long)documentWrapper.error.errorCode);
  } else if (documentWrapper.error) {
    shouldDeleteLocalCache = NO;
    MSLogError([MSDataStore logTag], @"Failed to call Cosmos with operation:%@ API: %@", pendingOperation,
               [documentWrapper.error.error localizedDescription]);
  }

  // Delete the document form the local cache.
  if (shouldDeleteLocalCache) {
    [self.dataOperationProxy.documentStore deleteWithToken:token documentId:documentId];
  }
}

@end