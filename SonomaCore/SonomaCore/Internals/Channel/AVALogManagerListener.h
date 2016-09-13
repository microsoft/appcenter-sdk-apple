/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVALogManagerListener <NSObject>

@optional

/**
 *  On processing log callback.
 *
 *  @param log      log.
 *  @param priority priority.
 */
- (void)onProcessingLog:(id<AVALog>)log withPriority:(AVAPriority)priority;

@end

