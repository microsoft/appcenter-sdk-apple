/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "SNMLog.h"
#import "SNMSerializableObject.h"

FOUNDATION_EXPORT NSString *const kSNMType;


@interface SNMAbstractLog : NSObject <SNMLog, SNMSerializableObject>

@end
