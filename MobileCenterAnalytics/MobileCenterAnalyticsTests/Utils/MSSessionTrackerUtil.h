/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@import Foundation;

@interface MSSessionTrackerUtil : NSObject

+ (void)simulateDidEnterBackgroundNotification;

+ (void)simulateWillEnterForegroundNotification;

@end
