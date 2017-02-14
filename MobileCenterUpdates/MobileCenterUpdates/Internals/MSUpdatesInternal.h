/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSUpdates.h"
#import "MSServiceInternal.h"
#import <Foundation/Foundation.h>

@interface MSUpdates ()

@property(nonatomic, copy) NSString *apiUrl;

@property(nonatomic, copy) NSString *installUrl;

- (NSString *)apiUrl;
- (NSString *)installUrl;

@end
