// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@interface MSPushLog : MSACAbstractLog

/**
 * Push token for push service
 */
@property(nonatomic, copy) NSString *pushToken;

@end
