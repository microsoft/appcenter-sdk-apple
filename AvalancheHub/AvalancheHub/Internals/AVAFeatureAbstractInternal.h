/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAFeature.h"
#import "AVAFeatureAbstract.h"
#import "AVAFeatureCommon.h"
#import "AVAFeatureInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstraction of features internal common logic.
 * This class is intended to be subclassed only not instantiated directly.
 * @see AVAFeatureInternal protocol, any feature subclassing this class must also conform to this protocol.
 */
@interface AVAFeatureAbstract () <AVAFeatureCommon>

/**
 *  flag that indicates if a feature has been initialised.
 */
@property BOOL featureInitialised;


#pragma mark - Module initialization

/**
 *  Create a feature.
 *
 *  @return A feature with common logic already implemented.
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END