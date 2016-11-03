/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface MSSessionTrackerHelper : NSObject

+ (void)simulateDidEnterBackgroundNotification;
+ (void)simulateWillEnterForegroundNotification;

@end
