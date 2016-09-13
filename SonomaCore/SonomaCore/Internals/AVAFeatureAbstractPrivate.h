/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAUserDefaults.h"
#import <Foundation/Foundation.h>

/**
 *  Private declarations for AVAFeatureAbstract.
 */
@interface AVAFeatureAbstract ()

/**
 *  isEnabled value storage key.
 */
@property(nonatomic, readonly) NSString *isEnabledKey;

/**
 *  Storage used for persistence.
 */
@property(nonatomic, readwrite) AVAUserDefaults *storage;

/**
 *  (For testing only) Create a feature with the given storage.
 *
 *  @param storage storage to persist data.
 *
 *  @return A feature with common logic already implemented.
 */
- (instancetype)initWithStorage:(AVAUserDefaults *)storage;
@end