/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAEventLog : AVALogWithProperties

/** Unique identifier for this event.
 */
@property(nonatomic) NSString *eventId;

/** Name of the event.
 */
@property(nonatomic) NSString *name;

@end
