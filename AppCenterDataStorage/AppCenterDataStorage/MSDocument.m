
#import <Foundation/Foundation.h>
#import "MSDocument.h"
#import "MSSerializableObject.h"

@implementation MSDocument


- (instancetype)initWithDocument:(id)document {
  
  if ((self = [super init])) {
    self.document = document;
  }
  return self;
}

// Non-serialized document (or null)
- (NSString *)jsonDocument {
  return @"";
}

//// get Deserialized document (or null)
//- (id)document {
//  MSDocument *doc = [[MSDocument alloc] init];
//  return doc;
//}

// set Deserialized document (or null)
- (void)setDocument:(id<NSCoding>)document
{
  if (document)
    document = nil;
}

// Error (or null)
- (MSDataSourceError *)error
{
  return nil;
}

// ID + document metadata
- (NSString *)partition
{
  return @"";
}

- (NSString *)documentId
{
  return nil;
}

- (NSString *)etag
{
  return nil;
}

- (NSDate *)timestamp
{
  return nil;
}

@end
