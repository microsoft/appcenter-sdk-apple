#import "MSSerializableDocument.h"

@class MSDataSourceError;

@interface MSDocumentWrapper<T : id <MSSerializableDocument>> : NSObject

// Non-serialized document (or null)
@property(nonatomic, strong, readonly) NSString *jsonValue;

// Document
@property(nonatomic, strong, readonly) T deserializedValue;

// Initialize object
- (instancetype)initWithDeserializedValue:(T)deserializedValue;

// Error (or null)
- (MSDataSourceError *)error;

// ID + document metadata
- (NSString *)partition;
- (NSString *)documentId;
- (NSString *)etag;
- (NSDate *)lastUpdatedDate;

// Flag indicating if the document was retrieved from the
// device cache instead of from CosmosDB
- (BOOL)fromDeviceCache;

@end
