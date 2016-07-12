/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVALogWithProperties.h"

@interface AVAEventLog : AVALogWithProperties

/** Unique identifier for this event.
 */
@property(nonatomic) NSUUID *eventId;

/** Name of the event.
 */
@property(nonatomic) NSString *name;

@end
