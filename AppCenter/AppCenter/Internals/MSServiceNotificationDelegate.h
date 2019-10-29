// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAppCenter;

@protocol MSServiceNotificationDelegate <NSObject>

@required

/**
 * A callback that is called when an App Center service notification is received.
 * @param appCenter The app center instance.
 * @param notificationData The service notification data.
 */
- (void)appCenter:(MSAppCenter *)appCenter didReceiveServiceNotification:(NSDictionary<NSString *, NSString *> *)notificationData;

@end
