/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@interface MSEventLog : MSLogWithProperties

/** 
 * Unique identifier for this event.
 */
@property(nonatomic, copy) NSString *eventId;

/**
 * Name of the event.
 */
@property(nonatomic, copy) NSString *name;

@end
