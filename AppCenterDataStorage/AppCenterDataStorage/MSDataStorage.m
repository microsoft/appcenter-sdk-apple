#import "MSDataStorage.h"
#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSDataStorageInternal.h"
#import "MSDataStoragePrivate.h"
#import "MSHttpIngestion.h"
#import "MSStorageIngestion.h"
#import "MSTokenExchange.h"
#import <Foundation/Foundation.h>

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"DataStorage";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"DataStorage";

/**
 * Singleton.
 */
static MSDataStorage *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSDataStorage

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _tokenExchangeUrl = kMSDefaultApiUrl;
  }
  return self;
}
#pragma mark - Service methods

+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
        completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)documentType;
  (void)completionHandler;
}

// List (need optional signature to configure page size)
// The document type (T) must be JSON deserializable
+ (void)readWithPartition:(NSString *)partition
             documentType:(Class)documentType
        completionHandler:(MSDownloadDocumentsCompletionHandler)completionHandler {
  (void)partition;
  (void)documentType;
  (void)completionHandler;
}

// Create a document
// The document instance (T) must be JSON serializable
+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
          completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {

  (void)partition;
  (void)documentId;
  (void)document;

  // Jump back on the MAIN THREAD to update the UI
  dispatch_async(dispatch_get_main_queue(), ^{
    MSDocument *doc = [[MSDocument alloc] initWithDocument:document];
    completionHandler(doc);
  });
}

// Replace a document
// The document instance (T) must be JSON serializable
+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
           completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)document;
  (void)completionHandler;
}

// Delete a document
+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(void (^)(MSDataSourceError *error))completionHandler {
  (void)partition;
  (void)documentId;
  (void)completionHandler;
}

#if TARGET_OS_OSX
- (void)dealloc {
}

#endif

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
  MSLogVerbose([MSDataStorage logTag], @"Started Data Storage service.");
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
}

#pragma mark - Public

+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl {
  [[MSDataStorage sharedInstance] setTokenExchangeUrl:tokenExchangeUrl];
}

@end
