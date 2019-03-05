#import "MSSerializableDocument.h"
#import "MSServiceAbstract.h"

@class MSDocumentWrapper<T : id<MSSerializableDocument>>;
@class MSPaginatedDocuments<T : id<MSSerializableDocument>>;
@class MSReadOptions;
@class MSWriteOptions;
@class MSDataStoreError;

/**
 * App Data Storage service.
 */

NS_ASSUME_NONNULL_BEGIN

// User documents
// An authenticated user can read/write documents in this partition
static NSString *const MSDataStoreUserDocumentsPartition = @"user-{userid}";

// Application partition
// Everyone can read documents in this partition
// Writes is not allowed via the SDK
static NSString *const MSDataStoreAppDocumentsPartition = @"readonly";

/**
 * Time to live constants
 */
static int const MSDataStoreTimeToLiveInfinite = -1;
static int const MSDataStoreTimeToLiveNoCache = 0;
static int const MSDataStoreTimeToLiveDefault = 60 * 60;

@interface MSDataStore<T : id <MSSerializableDocument>> : MSServiceAbstract

typedef void (^MSDocumentWrapperCompletionHandler)(MSDocumentWrapper<T> *document);
typedef void (^MSPaginatedDocumentsCompletionHandler)(MSPaginatedDocuments<T> *documents);
typedef void (^MSDataStoreErrorCompletionHandler)(MSDataStoreError *error);

/**
 * Change The URL that will be used for getting token.
 *
 * @param tokenExchangeUrl The new URL.
 */
+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl;

/**
 * Read a document.
 * The document type (T) must be JSON deserializable.
 */
+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * List of documents. Use optional signature to configure page size.
 * The document type (T) must be JSON deserializable.
 */
+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Create a document.
 * The document instance (T) must be JSON serializable.
 */
+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(T)document
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(T)document
               writeOptions:(MSWriteOptions *)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Replace a document.
 * The document instance (T) must be JSON serializable.
 */
+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(T)document
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(T)document
                writeOptions:(MSWriteOptions *)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Delete a document.
 */
+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(MSDataStoreErrorCompletionHandler)completionHandler;

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)writeOptions
                  completionHandler:(MSDataStoreErrorCompletionHandler)completionHandler;

//
// Nice to have
//

/**
 * Disable network connectivity on the DataStore module.
 * Read operations will be retrieved from the cache (if available)
 * Writes will be queued for later
 */
+ (void)disableNetworkWithCompletionHandler:(void (^)(void))completionHandler;

/**
 * Enable network connectivity on the DataStore module.
 */
+ (void)enableNetworkWithCompletionHandler:(void (^)(void))completionHandler;

@end
NS_ASSUME_NONNULL_END
