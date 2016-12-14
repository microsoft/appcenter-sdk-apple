/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface MSSessionTrackerUtil : NSObject

+ (void)simulateDidEnterBackgroundNotification;
+ (void)simulateWillEnterForegroundNotification;

@end
