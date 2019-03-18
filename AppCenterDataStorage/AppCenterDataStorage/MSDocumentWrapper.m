#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"

@implementation MSDocumentWrapper

@synthesize deserializedDocument  = _deserializedDocument;
@synthesize documentId = _documentId;
@synthesize partition = _partition;
@synthesize eTag = _eTag;
@synthesize lastUpdatedDate = _lastUpdatedDate;
@synthesize error = _error;

- (instancetype)initWithDeserializedDocument:(MSAbstractDocument *)deserializedDocument
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate {
  if ((self = [super init])) {
    _deserializedDocument = deserializedDocument;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
  }
  return self;
}

- (instancetype)initWithError:(NSError *)error documentId:(NSString *)documentId {
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
