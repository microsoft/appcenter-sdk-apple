/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVASessionTrackerDelegate <NSObject>

@required
- (void)sessionTracker:(id)sessionTracker didRenewSessionWithId:(NSString *)sessionId;

@end
