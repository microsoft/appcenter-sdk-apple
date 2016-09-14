/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import <Foundation/Foundation.h>

#import "SNMLog.h"
#import "SNMSerializableObject.h"

FOUNDATION_EXPORT NSString *const kSNMType;


@interface SNMAbstractLog : NSObject <SNMLog, SNMSerializableObject>

@end
