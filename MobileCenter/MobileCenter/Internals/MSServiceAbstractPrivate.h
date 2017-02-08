/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSUserDefaults.h"

@import Foundation;

/**
 *  Private declarations for MSServiceAbstract.
 */
@interface MSServiceAbstract ()

/**
 *  isEnabled value storage key.
 */
@property(nonatomic, copy, readonly) NSString *isEnabledKey;

/**
 *  Storage used for persistence.
 */
@property(nonatomic, readwrite) MSUserDefaults *storage;

/**
 *  (For testing only) Create a service with the given storage.
 *
 *  @param storage storage to persist data.
 *
 *  @return A service with common logic already implemented.
 */
- (instancetype)initWithStorage:(MSUserDefaults *)storage;
@end
