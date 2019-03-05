#import "MSDocumentWrapper.h"
#import "MSDataStoreError.h"
#import "MSSerializableObject.h"
#import <Foundation/Foundation.h>

@implementation MSDocumentWrapper

@synthesize jsonValue = _jsonValue;
@synthesize deserializedValue = _deserializedValue;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
  }
  return self;
}

// set Deserialized document (or null)
- (void)setDocument:(id<NSCoding>)document {
  if (document)
    document = nil;
}

// Error (or null)
- (MSDataSourceError *)error {
  return nil;
}

- (BOOL)fromDeviceCache {
  return false;
}

// ID + document metadata
- (NSString *)partition {
  return @"";
}

- (NSString *)documentId {
  return nil;
}

- (NSString *)etag {
  return nil;
}

- (NSDate *)lastUpdatedDate {
  return nil;
}

@end
