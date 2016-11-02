/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "MSLog.h"
#import "MSSerializableObject.h"

FOUNDATION_EXPORT NSString *const kMSType;


@interface MSAbstractLog : NSObject <MSLog, MSSerializableObject>

@end
