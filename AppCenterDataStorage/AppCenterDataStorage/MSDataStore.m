#import "MSDataStore.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSAuthTokenContext.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
<<<<<<< HEAD
#import "MSDataStoreError.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
=======
#import "MSCosmosDb.h"
#import "MSDataSourceError.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSDocumentUtils.h"
>>>>>>> 69305bcfd700425020dce2c771fb824a57a7cb00
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
 * CosmosDb Http code key.
 */
static NSString *const kMSCosmosDbHttpCodeKey = @"com.Microsoft.AppCenter.HttpCodeKey";

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
  // @todo
  (void)partition;
  (void)documentId;
  (void)documentType;
  (void)completionHandler;
}

+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  // @todo
  (void)partition;
  (void)documentId;
  (void)documentType;
  (void)readOptions;
  (void)completionHandler;
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
  // @todo
  (void)partition;
  (void)documentId;
  (void)document;
  (void)completionHandler;
}

+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {
  // @todo
  (void)partition;
  (void)documentId;
  (void)document;
  (void)writeOptions;
  (void)completionHandler;
}

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(MSDataStoreErrorCompletionHandler)completionHandler {
  // @todo
  (void)partition;
  (void)documentId;
  (void)completionHandler;
}

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)writeOptions
                  completionHandler:(MSDataStoreErrorCompletionHandler)completionHandler {
  // @todo
  (void)partition;
  (void)documentId;
  (void)writeOptions;
  (void)completionHandler;
}

#pragma mark - MSDataStore Implementation
- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *)__unused writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // TODO consume writeOptions
  [MSTokenExchange
             tokenAsync:(MSStorageIngestion *)self.ingestion
             partitions:@[ partition ]
      completionHandler:^(MSTokensResponse *_Nonnull tokenResponses, NSError *_Nonnull error) {
        // If error getting token.
        if (error || !tokenResponses) {
          MSLogError([MSDataStore logTag], @"Can't get CosmosDb token:%@", [error description]);
          completionHandler([[MSDocumentWrapper alloc] initWithError:error documentId:documentId]);
          return;
        }

        // Create http client.
        MSCosmosDbIngestion *cosmosDbIngestion = [[MSCosmosDbIngestion alloc] init];

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

        // Call CosmosDb.
        [MSCosmosDb
            performCosmosDbAsyncOperationWithHttpClient:cosmosDbIngestion
                                            tokenResult:tokenResponses.tokens[0]
                                             documentId:@""
                                             httpMethod:@"POST"
                                                   body:body
                                      completionHandler:^(NSData *_Nonnull data, NSError *_Nonnull cosmosDbError) {
                                        // If not created.
                                        NSNumber *errorCode = [cosmosDbError userInfo][kMSCosmosDbHttpCodeKey];
                                        if (!data || [errorCode integerValue] != MSHTTPCodesNo201Created) {
                                          MSLogError([MSDataStore logTag], @"Not able to create document:%@", [cosmosDbError description]);
                                          completionHandler([[MSDocumentWrapper alloc] initWithError:cosmosDbError documentId:documentId]);
                                          return;
                                        }

                                        // Deserialize.
                                        NSError *deserializeError;
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                             options:0
                                                                                               error:&deserializeError];
                                        if (deserializeError) {
                                          MSLogError([MSDataStore logTag], @"Error deserializing data:%@", [deserializeError description]);
                                        }
                                        MSLogDebug([MSDataStore logTag], @"Document json:%@", json);

                                        // Create a document.
                                        NSTimeInterval interval = [(NSString *)json[kMSDocumentTimestampKey] doubleValue];
                                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                                        NSString *eTag = json[kMSDocumentEtagKey];
                                        MSDocumentWrapper *docWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:document
                                                                                                                   partition:partition
                                                                                                                  documentId:documentId
                                                                                                                        eTag:eTag
                                                                                                             lastUpdatedDate:date];
                                        MSLogDebug([MSDataStore logTag], @"Document created:%@", data);
                                        completionHandler(docWrapper);
                                        return;
                                      }];
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
  }
}

#pragma mark - MSAuthTokenContextDelegate

- (void)authTokenContext:(MSAuthTokenContext *)__unused authTokenContext
     didReceiveAuthToken:(/* nullable (changed in #1328) */ NSString *)authToken {
  if (authToken == nil) {
    [MSTokenExchange removeAllCachedTokens];
  }
}

@end
