/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@interface MSPushLog : MSAbstractLog

@property(nonatomic) NSString *installationId;

@property(nonatomic) NSString *pushChannel;

@property(nonatomic) NSString *platform;

@property(nonatomic) NSArray<NSString *> *tags;

@end
