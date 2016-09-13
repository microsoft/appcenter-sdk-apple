/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "AVAAbstractLog.h"
#import <Foundation/Foundation.h>

@interface AVALogWithProperties : AVAAbstractLog

/* Additional key/value pair parameters.  [optional]
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *properties;

@end
