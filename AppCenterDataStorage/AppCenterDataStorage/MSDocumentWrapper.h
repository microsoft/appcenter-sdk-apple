#import "MSSerializableDocument.h"

@class MSDataSourceError;

@interface MSDocumentWrapper<T : id <MSSerializableDocument>> : NSObject

/**
 * Serialized document.
 */
@property(nonatomic, strong, readonly) NSString *jsonValue;

/**
 * Deserialized document.
 */
@property(nonatomic, strong, readonly) T deserializedValue;

/**
 * Partition.
 */
@property(nonatomic, strong, readonly) NSString *partition;

/**
 * Document Id.
 */
@property(nonatomic, strong, readonly) NSString *documentId;

/**
 * Document Etag.
 */
@property(nonatomic, strong, readonly) NSString *etag;

/**
 * Last update timestamp.
 */
@property(nonatomic, strong, readonly) NSDate *lastUpdatedDate;

/**
 * Document error.
 */
@property(nonatomic, strong, readonly) MSDataSourceError *error;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param deserializedValue The document value. Must conform to MSSerializableDocument protocol.
 * @param partition Partition key.
 * @param documentId Document id.
 * @param etag Document etag.
 * @param lastUpdatedDate Last updated date of the document.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithDeserializedValue:(T)deserializedValue
                                partition:(NSString *)partition
                               documetnId:(NSString *)documentId
                                     etag:(NSString *)etag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param error Document error.
 * @param documentId Document Id.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithError:(NSError *)error
                   documetnId:(NSString *)documentId;

/**
 * Check if the document is from the device cache.
 *
 * @return Flag indicating if the document was retrieved
 * from the device cache instead of from CosmosDB.
 */
- (BOOL)fromDeviceCache;

@end
