/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "AVAFeature.h"

@interface AVAAnalytics : NSObject <AVAFeature>

+ (void)sendEventLog:(NSString*)log;

@end
