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
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param deserializedValue The document value. Must conform to MSSerializableDocument protocol.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithDeserializedValue:(T)deserializedValue;

/**
 * Get error associated with document.
 *
 * @return Error in reading/updating the document. Null if no errors.
 */
- (MSDataSourceError *)error;

/**
 * Check if the document is from the device cache.
 *
 * @return Flag indicating if the document was retrieved
 * from the device cache instead of from CosmosDB.
 */
- (BOOL)fromDeviceCache;

/**
 * Document metadata and ID.
 */
- (NSString *)partition;
- (NSString *)documentId;
- (NSString *)etag;
- (NSDate *)lastUpdatedDate;

@end
