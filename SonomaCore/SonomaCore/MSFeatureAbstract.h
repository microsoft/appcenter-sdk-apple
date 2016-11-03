/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSFeature.h"
#import <Foundation/Foundation.h>

/**
 *  Abstraction of features common logic.
 * This class is intended to be subclassed only not instantiated directly.
 */
@interface MSFeatureAbstract : NSObject <MSFeature>
@end
