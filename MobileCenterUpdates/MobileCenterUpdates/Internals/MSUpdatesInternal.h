/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSUpdates.h"
#import "MSServiceInternal.h"
#import <Foundation/Foundation.h>

@interface MSUpdates ()

@property(nonatomic, copy) NSString *loginUrl;

@property(nonatomic, copy) NSString *updateUrl;

- (NSString *)loginUrl;
- (NSString *)updateUrl;

@end
