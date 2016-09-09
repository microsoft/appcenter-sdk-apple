/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Model/SNMLog.h"
#import "Utils/SNMConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol SNMSonomaDelegate <NSObject>

/**
 *  Track a log send from a feature.
 *
 *  @param feature  the log creator
 *  @param log      the log
 *  @param priority the log priority
 */
- (void)feature:(id)feature didCreateLog:(id<SNMLog>)log withPriority:(SNMPriority)priority;

@end
