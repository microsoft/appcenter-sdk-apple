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
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapper.h"
#import "MSHttpIngestion.h"
#import "MSPaginatedDocuments.h"
#import "MSReadOptions.h"
#import "MSStorageIngestion.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"
#import "MSWriteOptions.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"DataStorage";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"DataStorage";

/**
 * CosmosDb document timestamp key.
 */
static NSString *const kMSDocumentTimestampKey = @"_ts";

/**
 * CosmosDb document eTag key.
 */
static NSString *const kMSDocumentEtagKey = @"_etag";

/**
 * CosmosDb document key.
 */
static NSString *const kMSDocumentKey = @"document";

/**
 * CosmosDb upsert header key.
 */
static NSString *const kMSDocumentUpsertHeaderKey = @"x-ms-documentdb-is-upsert";

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
    _tokenExchangeUrl = kMSDefaultApiUrl;
  }
  return self;
}

#pragma mark - Public

+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl {
  [[MSDataStore sharedInstance] setTokenExchangeUrl:tokenExchangeUrl];
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
              readOptions:(MSReadOptions *)readOptions
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
  // @todo
  (void)partition;
  (void)documentType;
  (void)completionHandler;
}

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  // @todo
  (void)partition;
  (void)documentType;
  (void)readOptions;
  (void)completionHandler;
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
               writeOptions:(MSWriteOptions *)writeOptions
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
                writeOptions:(MSWriteOptions *)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self replaceWithPartition:partition
                  documentId:documentId
                    document:document
                writeOptions:writeOptions
           completionHandler:completionHandler];
}

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] deleteDocumentWithPartition:partition
                                                 documentId:documentId
                                               writeOptions:nil
                                          completionHandler:completionHandler];
}

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] deleteDocumentWithPartition:partition
                                                 documentId:documentId
                                               writeOptions:writeOptions
                                          completionHandler:completionHandler];
}

#pragma mark - MSDataStore Implementation

- (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // In the current version we do not support E-tag optimistic concurrency logic and replace will call create.
  [self createOrReplaceWithPartition:partition
                          documentId:documentId
                            document:document
                        writeOptions:writeOptions
                   additionalHeaders:@{kMSDocumentUpsertHeaderKey : @"true"}
                   completionHandler:completionHandler];
}

- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)__unused readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self performOperationForPartition:partition
                          documentId:documentId
                          httpMethod:kMSHttpMethodGet
                                body:nil
                   additionalHeaders:nil
                   completionHandler:^(NSData *data, NSError *_Nonnull cosmosDbError) {
                     // If not created.
                     if (!data || [MSDataSourceError errorCodeFromError:cosmosDbError] != kMSACDocumentSucceededErrorCode) {
                       MSLogError([MSDataStore logTag], @"Not able to read the document ID:%@ with error:%@", documentId,
                                  [cosmosDbError description]);
                       completionHandler([[MSDocumentWrapper alloc] initWithError:cosmosDbError documentId:documentId]);
                       return;
                     }

                     // Deserialize.
                     NSError *deserializeError;
                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializeError];
                     if (deserializeError) {
                       MSLogError([MSDataStore logTag], @"Error deserializing data:%@", [deserializeError description]);
                     }
                     MSLogDebug([MSDataStore logTag], @"Document json:%@", json);

                     // Create document.
                     id<MSSerializableDocument> deserializedDocument =
                         [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:(NSDictionary *)json[kMSDocumentKey]];
                     NSTimeInterval interval = [(NSString *)json[kMSDocumentTimestampKey] doubleValue];
                     NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                     NSString *eTag = json[kMSDocumentEtagKey];
                     MSDocumentWrapper *docWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedDocument
                                                                                                partition:partition
                                                                                               documentId:documentId
                                                                                                     eTag:eTag
                                                                                          lastUpdatedDate:date];
                     MSLogDebug([MSDataStore logTag], @"Document created:%@", data);
                     completionHandler(docWrapper);
                     return;
                   }];
}

- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self createOrReplaceWithPartition:partition
                          documentId:documentId
                            document:document
                        writeOptions:writeOptions
                   additionalHeaders:nil
                   completionHandler:completionHandler];
}

- (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)__unused writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler {
  [self performOperationForPartition:partition
                          documentId:documentId
                          httpMethod:kMSHttpMethodDelete
                                body:[NSData data]
                   additionalHeaders:nil
                   completionHandler:^(NSData *__unused data, NSError *_Nonnull cosmosDbError) {

                     // Body returned from call (data) is empty.
                     NSInteger httpStatusCode = [MSDataSourceError errorCodeFromError:cosmosDbError];
                     if (httpStatusCode != MSHTTPCodesNo204NoContent) {
                       MSLogError([MSDataStore logTag],
                                  @"Not able to delete document. Error: %@; HTTP status code: %ld; "
                                  @"Document: %@/%@",
                                  cosmosDbError.localizedDescription, (long)httpStatusCode, partition, documentId);
                     } else {
                       MSLogDebug([MSDataStore logTag], @"Document deleted: %@/%@", partition, documentId);
                     }
                     completionHandler([[MSDataSourceError alloc] initWithError:cosmosDbError]);
                   }];
}

- (void)createOrReplaceWithPartition:(NSString *)partition
                          documentId:(NSString *)documentId
                            document:(id<MSSerializableDocument>)document
                        writeOptions:(MSWriteOptions *)__unused writeOptions
                   additionalHeaders:(NSDictionary *)additionalHeaders
                   completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // Create document payload.
  NSError *serializationError;
  NSDictionary *dic = [MSDocumentUtils documentPayloadWithDocumentId:documentId
                                                           partition:partition
                                                            document:[document serializeToDictionary]];
  NSData *body = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializationError];
  if (!body || serializationError) {
    MSLogError([MSDataStore logTag], @"Error serializing data:%@", [serializationError description]);
    completionHandler([[MSDocumentWrapper alloc] initWithError:serializationError documentId:documentId]);
    return;
  }
  [self performOperationForPartition:partition
                          documentId:nil
                          httpMethod:kMSHttpMethodPost
                                body:body
                   additionalHeaders:additionalHeaders
                   completionHandler:^(NSData *_Nonnull data, NSError *_Nonnull cosmosDbError) {
                     // If not created.
                     NSInteger errorCode = [MSDataSourceError errorCodeFromError:cosmosDbError];
                     if (!data || (errorCode != kMSACDocumentCreatedErrorCode && errorCode != kMSACDocumentSucceededErrorCode)) {
                       MSLogError([MSDataStore logTag], @"Not able to create/replace document: %@", [cosmosDbError description]);
                       completionHandler([[MSDocumentWrapper alloc] initWithError:cosmosDbError documentId:documentId]);
                       return;
                     }

                     // Deserialize.
                     NSError *deserializeError;
                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializeError];
                     if (deserializeError) {
                       MSLogError([MSDataStore logTag], @"Error deserializing data:%@", [deserializeError description]);
                     }
                     MSLogDebug([MSDataStore logTag], @"Document json:%@", json);

                     // Create an instance of Document.
                     Class aClass = [document class];
                     id<MSSerializableDocument> deserializedDocument =
                         [(id<MSSerializableDocument>)[aClass alloc] initFromDictionary:(NSDictionary *)json[kMSDocumentKey]];

                     // Create a document.
                     NSTimeInterval interval = [(NSString *)json[kMSDocumentTimestampKey] doubleValue];
                     NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                     NSString *eTag = json[kMSDocumentEtagKey];
                     MSDocumentWrapper *docWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedDocument
                                                                                                partition:partition
                                                                                               documentId:documentId
                                                                                                     eTag:eTag
                                                                                          lastUpdatedDate:date];
                     MSLogDebug([MSDataStore logTag], @"Document created/replaced with ID: %@", documentId);
                     completionHandler(docWrapper);
                     return;
                   }];
}

- (void)performOperationForPartition:(NSString *)partition
                          documentId:(NSString *)documentId
                          httpMethod:(NSString *)httpMethod
                                body:(NSData *)body
                   additionalHeaders:(NSDictionary *)additionalHeaders
                   completionHandler:(MSCosmosDbCompletionHandler)completionHandler {
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(MSStorageIngestion *)self.ingestion
                                                    partition:partition
                                            completionHandler:^(MSTokensResponse *_Nonnull tokenResponses, NSError *_Nonnull error) {
                                              if (error || [tokenResponses.tokens count] == 0) {
                                                NSInteger httpStatusCode = [MSDataSourceError errorCodeFromError:error];
                                                MSLogError([MSDataStore logTag],
                                                           @"Can't get CosmosDb token. Error: %@;  HTTP status code: %ld; Partition: %@",
                                                           error.localizedDescription, (long)httpStatusCode, partition);
                                                completionHandler(nil, error);
                                                return;
                                              }
                                              MSCosmosDbIngestion *cosmosDbIngestion = [MSCosmosDbIngestion new];
                                              [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:cosmosDbIngestion
                                                                                          tokenResult:tokenResponses.tokens[0]
                                                                                           documentId:documentId
                                                                                           httpMethod:httpMethod
                                                                                                 body:body
                                                                                    additionalHeaders:additionalHeaders
                                                                                    completionHandler:completionHandler];
                                            }];
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [self new];
    }
  });
  return sharedInstance;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];

  // Make sure that ingestion hasn't already been initialized.
  if (appSecret && !self.ingestion) {
    self.ingestion = [[MSStorageIngestion alloc] initWithBaseUrl:self.tokenExchangeUrl appSecret:(NSString *)appSecret];
  }
  MSLogVerbose([MSDataStore logTag], @"Started Data Storage service.");
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
  if (isEnabled) {
    [[MSAuthTokenContext sharedInstance] addDelegate:self];
  } else {
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [MSTokenExchange removeAllCachedTokens];
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext didSetNewAccountIdWithAuthToken:(NSString *)authToken {
  if (!authToken) {
    [MSTokenExchange removeAllCachedTokens];
  }
}

@end
