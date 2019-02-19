#import <Foundation/Foundation.h>
#import "MSDataSourceError.h"

@interface MSDocument<T : id<NSCoding>> : NSObject

// Non-serialized document (or null)
@property(nonatomic, strong, readonly) NSString *jsonDocument;

// Document
@property(nonatomic, strong, readonly) T document;

// Initialize object
- (instancetype)initWithDocument:(id)document;

// Error (or null)
- (MSDataSourceError *)error;

// ID + document metadata
- (NSString *)partition;
- (NSString *)documentId;
- (NSString *)etag;
- (NSDate *)timestamp;

@end
