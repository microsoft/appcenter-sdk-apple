// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentChange.h"

@implementation MSDocumentChange

static NSString *const kMSDocumentChangeId = @"id";
static NSString *const kMSDocumentChangePartition = @"ptn";
static NSString *const kMSDocumentChangeOperation = @"op";
static NSString *const kMSDocumentChangeTimestamp = @"_ts";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init]) != nil) {
    _documentId = (NSString * _Nonnull) dictionary[kMSDocumentChangeId];
    _partition = (NSString * _Nonnull) dictionary[kMSDocumentChangePartition];
    _operation = (NSString * _Nonnull) dictionary[kMSDocumentChangeOperation];
    _timestamp = [(NSNumber * _Nonnull) dictionary[kMSDocumentChangeTimestamp] longValue];
  }
  return self;
}

@end
