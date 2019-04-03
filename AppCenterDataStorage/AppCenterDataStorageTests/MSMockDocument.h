// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSSerializableDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSMockDocument : NSObject<MSSerializableDocument>

@property NSDictionary *contentDictionary;

@end

NS_ASSUME_NONNULL_END
