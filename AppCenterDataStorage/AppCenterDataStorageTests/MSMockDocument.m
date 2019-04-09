// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSMockDocument.h"

@implementation MSMockDocument

- (nonnull instancetype)initFromDictionary:(nonnull NSDictionary *)dictionary {
  if ((self = [super init])) {
    _contentDictionary = dictionary;
  }
  return self;
}

- (nonnull NSDictionary *)serializeToDictionary {
  return self.contentDictionary;
}

@end
