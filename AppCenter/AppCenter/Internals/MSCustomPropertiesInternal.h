// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MS_CUSTOM_PROPERTIES_INTERNAL_H
#define MS_CUSTOM_PROPERTIES_INTERNAL_H

#import "MSCustomProperties.h"

/**
 *  Private declarations for MSCustomProperties.
 */
@interface MSCustomProperties ()

/**
 * Create an immutable copy of the properties dictionary to use in synchronized scenarios.
 *
 * @return An immutable copy of properties.
 */
- (NSDictionary<NSString *, NSObject *> *)propertiesImmutableCopy;

@end

#endif
