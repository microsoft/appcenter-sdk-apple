/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVALogWithProperties.h"

@interface AVAPageLog : AVALogWithProperties

/** Name of the event.
 */
@property(nonatomic) NSString *name;

@end
