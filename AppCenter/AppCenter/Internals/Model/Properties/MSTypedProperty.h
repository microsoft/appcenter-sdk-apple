// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableObject.h"

static NSString *const kMSTypedPropertyValue = @"value";

@interface MSTypedProperty : NSObject <MSSerializableObject>

/**
 * Property type.
 */
@property(nonatomic, copy) NSString *type;

/**
 * Property name.
 */
@property(nonatomic, copy) NSString *name;

@end
