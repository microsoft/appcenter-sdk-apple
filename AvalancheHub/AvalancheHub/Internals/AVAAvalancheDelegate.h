/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Model/AVALog.h"
#import "Utils/AVAConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol AVAAvalancheDelegate <NSObject>

/**
 *  Track a log send from a feature.
 *
 *  @param feature  the log creator
 *  @param log      the log
 *  @param priority the log priority
 */
- (void)feature:(id)feature didCreateLog:(id<AVALog>)log withPriority:(AVAPriority)priority;

/**
 *  Session tracking callback.
 *
 *  @param sessionTracker session tracker object.
 *  @param sessionId      new session id.
 */
- (void)sessionTracker:(id)sessionTracker didRenewSessionWithId:(NSString *)sessionId;

@end
