/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMFeature.h"
#import "SNMFeatureAbstract.h"
#import "SNMFeatureCommon.h"
#import "SNMFeatureInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstraction of features internal common logic.
 * This class is intended to be subclassed only not instantiated directly.
 * @see SNMFeatureInternal protocol, any feature subclassing this class must also conform to this protocol.
 */
@interface SNMFeatureAbstract () <SNMFeatureCommon>

/**
 * Flag indicating if a feature has been started or not.
 */
@property(nonatomic, readwrite) BOOL started;

#pragma mark - Module initialization

/**
 * Create a feature.
 *
 * @return A feature with common logic already implemented.
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
