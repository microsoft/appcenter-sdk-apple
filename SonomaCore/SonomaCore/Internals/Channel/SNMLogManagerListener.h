/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "SNMConstants+Internal.h"

@protocol SNMLogManagerListener <NSObject>

@optional

/**
 *  On processing log callback.
 *
 *  @param log      log.
 *  @param priority priority.
 */
- (void)onProcessingLog:(id<SNMLog>)log withPriority:(SNMPriority)priority;

@end

