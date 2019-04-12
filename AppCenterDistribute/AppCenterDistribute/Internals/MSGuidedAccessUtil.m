// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSGuidedAccessUtil.h"
#import <UIKit/UIKit.h>

@implementation MSGuidedAccessUtil

+(BOOL)isGuidedAccessEnabled{
  return UIAccessibilityIsGuidedAccessEnabled();
}

@end
