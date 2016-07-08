/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AvalancheHub+Internal.h"

@interface AVAEventLog : AVALogWithProperties

/** Unique identifier for this event.
 */
@property(nonatomic) NSUUID *_id;

/** Name of the event.
 */
@property(nonatomic) NSString *name;

@end
