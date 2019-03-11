#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"
#import "MSSerializableObject.h"

@implementation MSDocumentWrapper

@synthesize jsonValue = _jsonValue;
@synthesize deserializedValue = _deserializedValue;
@synthesize documentId = _documentId;
@synthesize partition = _partition;
@synthesize etag = _etag;
@synthesize lastUpdatedDate = _lastUpdatedDate;
@synthesize error = _error;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                partition:(NSString *)partition
                               documetnId:(NSString *)documentId
                                     etag:(NSString *)etag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
    _partition = partition;
    _documentId = documentId;
    _etag = etag;
    _lastUpdatedDate = lastUpdatedDate;
  }
  return self;
}

- (instancetype)initWithError:(NSError *)error documetnId:(NSString *)documentId {
  if ((self = [super init])) {
    _documentId = documentId;
    _error = [[MSDataSourceError alloc] initWithError:error];
  }
  return self;
}

- (BOOL)fromDeviceCache {
  // @todo
  return false;
}

@end
