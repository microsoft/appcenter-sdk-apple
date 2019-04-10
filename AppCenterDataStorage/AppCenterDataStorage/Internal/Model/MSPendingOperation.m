// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPendingOperation.h"

@implementation MSPendingOperation

@synthesize partition = _partition;
@synthesize documentId = _documentId;
@synthesize document = _document;
@synthesize etag = _etag;
@synthesize expirationTime = _expirationTime;

- (instancetype)initWithOperation:(NSString *)operation
                        partition:(NSString *)partition
                       documentId:(NSString *)documentId
                         document:(NSString *)document
                             etag:(NSString *)etag
                   expirationTime:(NSTimeInterval)expirationTime {
  if ((self = [super init])) {
    _operation = operation;
    _partition = partition;
    _documentId = documentId;
    _document = document;
    _etag = etag;
    _expirationTime = expirationTime;
  }
  return self;
}

@end
