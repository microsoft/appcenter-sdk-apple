/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAbstractLog.h"
#import <Foundation/Foundation.h>

@interface AVALogWithProperties : AVAAbstractLog

/* Additional key/value pair parameters.  [optional]
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *properties;

@end
