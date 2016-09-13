/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import <Foundation/Foundation.h>

#import "AVALog.h"
#import "AVASerializableObject.h"

FOUNDATION_EXPORT NSString *const kAVAType;


@interface AVAAbstractLog : NSObject <AVALog, AVASerializableObject>

@end
