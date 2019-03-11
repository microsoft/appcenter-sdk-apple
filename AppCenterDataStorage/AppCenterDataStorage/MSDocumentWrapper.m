#import "MSDocumentWrapper.h"
#import "MSDataStoreError.h"
#import "MSSerializableObject.h"

@implementation MSDocumentWrapper

@synthesize jsonValue = _jsonValue;
@synthesize deserializedValue = _deserializedValue;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
  }
  return self;
}

- (MSDataSourceError *)error {
  // @todo
  return nil;
}

- (BOOL)fromDeviceCache {
  // @todo
  return false;
}

// ID + document metadata
- (NSString *)partition {
  // @todo
  return @"";
}

- (NSString *)documentId {
  // @todo
  return nil;
}

- (NSString *)etag {
  // @todo
  return nil;
}

- (NSDate *)lastUpdatedDate {
  // @todo
  return nil;
}

@end
