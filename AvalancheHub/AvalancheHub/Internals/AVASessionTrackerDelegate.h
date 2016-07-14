/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVASessionTrackerDelegate <NSObject>

@required
- (void)sessionDidRenewed:(NSString *)sessionId;

@end
