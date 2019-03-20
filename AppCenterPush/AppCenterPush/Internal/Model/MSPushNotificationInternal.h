// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPushNotification.h"

@interface MSPushNotification ()

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message customData:(NSDictionary<NSString *, NSString *> *)customData;

@end
