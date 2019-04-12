// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDistributeTestUtil : NSObject

/**
 * App Center mock.
 */
@property(class, nonatomic) id appCenterMock;

/**
 * App Center util mock.
 */
@property(class, nonatomic) id utilMock;

/**
 * Guided access util mock.
 */
@property(class, nonatomic) id guidedAccessUtilMock;

/**
 * Mock the conditions to allow updates.
 */
+ (void)mockUpdatesAllowedConditions;

/**
 * Unmock the conditions to allow updates.
 */
+ (void)unMockUpdatesAllowedConditions;

@end
