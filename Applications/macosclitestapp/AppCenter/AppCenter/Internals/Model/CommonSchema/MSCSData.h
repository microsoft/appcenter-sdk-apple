// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSOrderedDictionary.h"
#import "MSSerializableObject.h"

static NSString *const kMSDataBaseData = @"baseData";
static NSString *const kMSDataBaseType = @"baseType";

/**
 * The data object contains Part B and Part C properties.
 */
@interface MSCSData : NSObject <MSSerializableObject, MSModel>

@property(atomic, copy) NSDictionary *properties;

@end
