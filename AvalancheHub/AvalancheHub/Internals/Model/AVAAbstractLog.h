/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVALog.h"

FOUNDATION_EXPORT NSString *const kAVAType;

@interface AVAAbstractLog : NSObject <AVALog, NSCoding>

@end
