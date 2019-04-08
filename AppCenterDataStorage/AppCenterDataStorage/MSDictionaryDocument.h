// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"

@interface MSDictionaryDocument : NSObject <MSSerializableDocument>

/**
 * The dictionary.
 */
@property(readonly) NSDictionary *dictionary;

@end
