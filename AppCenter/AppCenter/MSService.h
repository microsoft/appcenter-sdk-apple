// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MS_SERVICE_H
#define MS_SERVICE_H

#import <Foundation/Foundation.h>

/**
 * Protocol declaring service logic.
 */
@protocol MSService <NSObject>

/**
 * Indicates whether this service is enabled.
 *
 * The state is persisted in the device's storage across application launches.
 */
@property(class, nonatomic, assign, setter=setEnabled:) BOOL isEnabled;

@end

#endif
