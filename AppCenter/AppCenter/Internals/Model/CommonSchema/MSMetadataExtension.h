// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSFieldDelimiter = @"f";

/**
 * The metadata section contains additional typing/schema-related information for each field in the Part B or Part C payload.
 */
@interface MSMetadataExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Additional typing/schema-related information for each field in the Part B or Part C payload.
 */
@property(atomic, copy) NSDictionary *metadata;

@end
