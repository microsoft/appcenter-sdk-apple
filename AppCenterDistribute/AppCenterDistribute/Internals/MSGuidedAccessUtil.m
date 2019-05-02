// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIKit.h>

#import "MSGuidedAccessUtil.h"

@implementation MSGuidedAccessUtil

+ (BOOL)isGuidedAccessEnabled {
  return UIAccessibilityIsGuidedAccessEnabled();
}

@end
