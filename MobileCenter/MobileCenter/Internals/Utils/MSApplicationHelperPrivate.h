/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSApplicationHelper.h"
#import <UIKit/UIKit.h>

@interface MSApplicationHelper ()

/**
 * Get the shared app state.
 *
 * @discussion This method is exposed for testing purposes. The shared app state is resolved at runtime by this method
 * which makes the UIApplication not mockable. This method is meant to be stubbed in tests to inject the desired
 * application states.
 * @return The shared app state.
 */
+ (UIApplicationState)sharedAppState;

@end