/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface AVASessionTrackerHelper : NSObject

+ (void) simulateDidEnterBackgroundNotification;
+ (void) simulateWillEnterForegroundNotification;

@end
