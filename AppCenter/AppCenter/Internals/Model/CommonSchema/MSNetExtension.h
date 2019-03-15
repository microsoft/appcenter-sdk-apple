// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSNetProvider = @"provider";

/**
 * The network extension contains network properties.
 */
@interface MSNetExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The network provider.
 */
@property(nonatomic, copy) NSString *provider;

@end
