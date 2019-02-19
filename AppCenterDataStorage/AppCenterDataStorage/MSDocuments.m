
#import <Foundation/Foundation.h>
#import "MSDocuments.h"
#import "MSSerializableObject.h"

@implementation MSDocuments

// List of documents in the current page (or null)
- (NSArray<MSDocument<id<NSCoding>> *> *)documents {
  return nil;
}

// List of documents (deserialized) in the current page (or null)
- (NSArray<id> *)asList
{
  return nil;
}

// Error (or null)
- (MSDataSourceError *)error
{
  return nil;
}

// Flag indicating if an extra page can be fetched
- (BOOL)hasNext
{
  return NO;
}

- (MSDocument<id<NSCoding>> *)next
{
  return nil;
}

@end
