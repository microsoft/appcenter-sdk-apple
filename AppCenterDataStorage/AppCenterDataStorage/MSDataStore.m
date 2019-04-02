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
#import "MSHttpClient.h"
#import "MSPaginatedDocuments.h"
#import "MSReadOptions.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"
#import "MSWriteOptions.h"

// Constants.
static NSString *const kMSServiceName = @"DataStorage";
static NSString *const kMSGroupId = @"DataStorage";
static NSString *const kMSDocumentIdKey = @"id";
static NSString *const kMSDocumentTimestampKey = @"_ts";
static NSString *const kMSDocumentEtagKey = @"_etag";
static NSString *const kMSDocumentKey = @"document";
static NSString *const kMSDocumentUpsertHeaderKey = @"x-ms-documentdb-is-upsert";
static NSString *const kMSDocumentContinuationTokenHeaderKey = @"x-ms-continuation";

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
                                      readOptions:nil
                                continuationToken:nil
                                completionHandler:completionHandler];
}

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] listWithPartition:partition
                                     documentType:documentType
                                      readOptions:readOptions
                                continuationToken:nil
                                completionHandler:completionHandler];
}

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        continuationToken:(NSString *_Nullable)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] listWithPartition:partition
                                     documentType:documentType
                                      readOptions:readOptions
                                continuationToken:continuationToken
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
                       writeOptions:(MSWriteOptions *_Nullable)writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler {
  [[MSDataStore sharedInstance] deleteDocumentWithPartition:partition
                                                 documentId:documentId
                                               writeOptions:writeOptions
                                          completionHandler:completionHandler];
}

+ (void)setOfflineModeEnabled:(BOOL)offlineModeEnabled {
  [MSDataStore sharedInstance].offlineModeEnabled = offlineModeEnabled;
}

+ (BOOL)isOfflineModeEnabled {
  return [MSDataStore sharedInstance].offlineModeEnabled;
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
                   completionHandler:completionHandler];
}

- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)__unused readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  [self performOperationForPartition:partition
                          documentId:documentId
                          httpMethod:kMSHttpMethodGet
                                body:nil
                   additionalHeaders:nil
                   completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable __unused response,
                                       NSError *_Nullable cosmosDbError) {
                     // If not created.
                     if (!data || [MSDataSourceError errorCodeFromError:cosmosDbError] != MSACDocumentSucceededErrorCode) {
                       MSLogError([MSDataStore logTag], @"Not able to read the document ID:%@ with error:%@", documentId,
                                  [cosmosDbError description]);
                       completionHandler([[MSDocumentWrapper alloc] initWithError:cosmosDbError documentId:documentId]);
                       return;
                     }

                     // Deserialize.
                     NSError *deserializeError;
                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:(NSData * _Nonnull) data
                                                                          options:0
                                                                            error:&deserializeError];
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
                     MSDocumentWrapper *docWrapper = [[MSDocumentWrapper alloc]
                         initWithDeserializedValue:deserializedDocument
                                         jsonValue:[[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding]
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
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
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
                       writeOptions:(MSWriteOptions *_Nullable)__unused writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler {
  [self performOperationForPartition:partition
                          documentId:documentId
                          httpMethod:kMSHttpMethodDelete
                                body:[NSData data]
                   additionalHeaders:nil
                   completionHandler:^(NSData *_Nullable __unused responseBody, NSHTTPURLResponse *_Nullable __unused response,
                                       NSError *_Nullable cosmosDbError) {
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
                        writeOptions:(MSWriteOptions *_Nullable)__unused writeOptions
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
                          documentId:documentId
                          httpMethod:kMSHttpMethodPost
                                body:body
                   additionalHeaders:additionalHeaders
                   completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable __unused response,
                                       NSError *_Nullable cosmosDbError) {
                     // If not created.
                     NSInteger errorCode = [MSDataSourceError errorCodeFromError:cosmosDbError];
                     if (!data || (errorCode != MSACDocumentCreatedErrorCode && errorCode != MSACDocumentSucceededErrorCode)) {
                       MSLogError([MSDataStore logTag], @"Not able to create/replace document: %@", [cosmosDbError description]);
                       completionHandler([[MSDocumentWrapper alloc] initWithError:cosmosDbError documentId:documentId]);
                       return;
                     }

                     // Deserialize.
                     NSError *deserializeError;
                     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:(NSData * _Nonnull) data
                                                                          options:0
                                                                            error:&deserializeError];
                     if (deserializeError) {
                       MSLogError([MSDataStore logTag], @"Error deserializing data:%@", [deserializeError description]);
                       completionHandler([[MSDocumentWrapper alloc] initWithError:deserializeError documentId:documentId]);
                       return;
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
                     MSDocumentWrapper *docWrapper = [[MSDocumentWrapper alloc]
                         initWithDeserializedValue:deserializedDocument
                                         jsonValue:[[NSString alloc] initWithData:(NSData *)data encoding:NSUTF8StringEncoding]
                                         partition:partition
                                        documentId:documentId
                                              eTag:eTag
                                   lastUpdatedDate:date];
                     MSLogDebug([MSDataStore logTag], @"Document created/replaced with ID: %@", documentId);
                     completionHandler(docWrapper);
                     return;
                   }];
}

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        continuationToken:(nullable NSString *)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {
  NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
  if (continuationToken) {
    [additionalHeaders setObject:(NSString *)continuationToken forKey:kMSDocumentContinuationTokenHeaderKey];
  }

  // Call cosmos DB.
  [self performOperationForPartition:partition
                          documentId:nil
                          httpMethod:kMSHttpMethodGet
                                body:nil
                   additionalHeaders:additionalHeaders
                   completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable cosmosDbError) {
                     // If not OK.
                     if (!data || [MSDataSourceError errorCodeFromError:cosmosDbError] != MSACDocumentSucceededErrorCode) {
                       MSLogError([MSDataStore logTag], @"Not able to retrieve documents: %@", [cosmosDbError description]);
                       MSDataSourceError *dataSourceCosmosDbError = [[MSDataSourceError alloc] initWithError:cosmosDbError];
                       MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:dataSourceCosmosDbError];
                       completionHandler(documents);
                       return;
                     }

                     // Deserialize the list payload and try to get the array of documents.
                     NSError *deserializeError;
                     id jsonPayload = [NSJSONSerialization JSONObjectWithData:(NSData *)data options:0 error:&deserializeError];
                     NSDictionary *jsonPayloadDict = nil;
                     NSArray *jsonDocuments = nil;
                     if (!deserializeError && jsonPayload && [(NSObject *)jsonPayload isKindOfClass:[NSDictionary class]]) {
                       jsonPayloadDict = (NSDictionary *)jsonPayload;
                     }
                     if (jsonPayloadDict && [jsonPayloadDict objectForKey:@"Documents"] &&
                         [(NSObject *)jsonPayloadDict[@"Documents"] isKindOfClass:[NSArray class]]) {
                       jsonDocuments = jsonPayloadDict[@"Documents"];
                     }
                     if (!jsonDocuments) {
                       if (!deserializeError)
                         deserializeError = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                                       code:MSACDataStoreErrorJSONSerializationFailed
                                                                   userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize documents"}];
                       MSDataSourceError *dataSourceDeserializeError = [[MSDataSourceError alloc] initWithError:deserializeError];
                       MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:dataSourceDeserializeError];
                       completionHandler(documents);
                       return;
                     }

                     // Parse the documents.
                     NSMutableArray<MSDocumentWrapper *> *items = [NSMutableArray new];
                     for (id document in jsonDocuments) {
                       // Deserialize current document.
                       // TODO: handle deserialization here.
                       id<MSSerializableDocument> deserializedDocument =
                           [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:(NSDictionary *)document];

                       // Create a document wrapper object.
                       // TODO: handle deserialization error for CosmosDB internal properties here.
                       NSTimeInterval interval = [(NSString *)document[kMSDocumentTimestampKey] doubleValue];
                       NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                       NSString *documentId = document[kMSDocumentIdKey];
                       NSString *eTag = document[kMSDocumentEtagKey];
                       NSString *jsonValue;
                       {
                         NSError *error;
                         NSData *jsonData = [NSJSONSerialization dataWithJSONObject:document options:0 error:&error];
                         if (!error)
                           jsonValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                       }
                       [items addObject:[[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedDocument
                                                                                   jsonValue:jsonValue
                                                                                   partition:partition
                                                                                  documentId:documentId
                                                                                        eTag:eTag
                                                                             lastUpdatedDate:date]];
                     }

                     // Instantiate the first page and return it.
                     MSPage *page = [[MSPage alloc] initWithItems:items];
                     MSPaginatedDocuments *documents =
                         [[MSPaginatedDocuments alloc] initWithPage:page
                                                          partition:partition
                                                       documentType:documentType
                                                        readOptions:readOptions
                                                  continuationToken:[response allHeaderFields][kMSDocumentContinuationTokenHeaderKey]];
                     completionHandler(documents);
                   }];
}

- (void)performOperationForPartition:(NSString *)partition
                          documentId:(NSString *)documentId
                          httpMethod:(NSString *)httpMethod
                                body:(NSData *)body
                   additionalHeaders:(NSDictionary *)additionalHeaders
                   completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)self.httpClient
                                             tokenExchangeUrl:self.tokenExchangeUrl
                                                    appSecret:self.appSecret
                                                    partition:partition
                                            completionHandler:^(MSTokensResponse *_Nonnull tokenResponses, NSError *_Nonnull error) {
                                              if (error || [tokenResponses.tokens count] == 0) {
                                                NSInteger httpStatusCode = [MSDataSourceError errorCodeFromError:error];
                                                MSLogError([MSDataStore logTag],
                                                           @"Can't get CosmosDb token. Error: %@;  HTTP status code: %ld; Partition: %@",
                                                           error.localizedDescription, (long)httpStatusCode, partition);
                                                completionHandler(nil, nil, error);
                                                return;
                                              }
                                              [MSCosmosDb
                                                  performCosmosDbAsyncOperationWithHttpClient:(MSHttpClient * _Nonnull) self.httpClient
                                                                                  tokenResult:tokenResponses.tokens[0]
                                                                                   documentId:documentId
                                                                                   httpMethod:httpMethod
                                                                                         body:body
                                                                            additionalHeaders:additionalHeaders
                                                                           offlineModeEnabled:self.offlineModeEnabled
                                                                            completionHandler:completionHandler];
                                            }];
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
  } else {
    [[MSAuthTokenContext sharedInstance] removeDelegate:self];
    [MSTokenExchange removeAllCachedTokens];
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext didUpdateAccountIdWithAuthToken:(NSString *)authToken {
  if (!authToken) {
    [MSTokenExchange removeAllCachedTokens];
  }
}

@end
