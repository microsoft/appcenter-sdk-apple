/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSUserDefaults.h"
#import <Foundation/Foundation.h>

/**
 *  Private declarations for SNMFeatureAbstract.
 */
@interface MSFeatureAbstract ()

/**
 *  isEnabled value storage key.
 */
@property(nonatomic, readonly) NSString *isEnabledKey;

/**
 *  Storage used for persistence.
 */
@property(nonatomic, readwrite) MSUserDefaults *storage;

/**
 *  (For testing only) Create a feature with the given storage.
 *
 *  @param storage storage to persist data.
 *
 *  @return A feature with common logic already implemented.
 */
- (instancetype)initWithStorage:(MSUserDefaults *)storage;
@end
