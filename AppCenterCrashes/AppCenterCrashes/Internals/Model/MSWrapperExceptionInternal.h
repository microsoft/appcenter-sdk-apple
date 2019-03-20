// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableObject.h"
#import "MSWrapperException.h"

/**
 * MSWrapperException must be serializable, but only internally (so that MSSerializableObject does not need to be bound for wrapper SDKs)
 */
@interface MSWrapperException () <MSSerializableObject>
@end
