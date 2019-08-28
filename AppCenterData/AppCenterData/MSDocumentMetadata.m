// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentMetadata.h"

@implementation MSDocumentMetadata

- (instancetype)initWithPartition:(NSString *)partition
                       documentId:(NSString *)documentId
                             eTag:(NSString *)eTag {
  if ((self = [super init])) {
    _documentId = documentId;
    _partition = partition;
    _eTag = eTag;
  }
  return self;
}

@end
