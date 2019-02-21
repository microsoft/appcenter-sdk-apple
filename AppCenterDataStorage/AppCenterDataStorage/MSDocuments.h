#import <Foundation/Foundation.h>
#import "MSDataSourceError.h"
#import "MSDocument.h"
#import "MSSerializableDocument.h"

// A (paginated) list of documents from CosmosDB
@interface MSDocuments<T : id<MSSerializableDocument>> : NSObject

// List of documents in the current page (or null)
- (NSArray<MSDocument<T> *> *)documents;

// List of documents (deserialized) in the current page (or null)
- (NSArray<T> *)asList;

// Error (or null)
- (MSDataSourceError *)error;

// Flag indicating if an extra page can be fetched
- (BOOL)hasNext;

- (MSDocument<T> *)next;

@end
