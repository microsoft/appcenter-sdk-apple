/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol MSLogManagerDelegate <NSObject>

@optional

/**
 *  On processing log callback.
 *
 *  @param log      log.
 *  @param priority priority.
 */
- (void)onProcessingLog:(id<MSLog>)log withPriority:(MSPriority)priority;

@end
