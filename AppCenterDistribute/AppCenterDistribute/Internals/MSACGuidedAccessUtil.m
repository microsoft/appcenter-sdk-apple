// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIKit.h>

#import "MSACGuidedAccessUtil.h"

@implementation MSACGuidedAccessUtil

+ (BOOL)isGuidedAccessEnabled {
  return UIAccessibilityIsGuidedAccessEnabled();
}

@end
