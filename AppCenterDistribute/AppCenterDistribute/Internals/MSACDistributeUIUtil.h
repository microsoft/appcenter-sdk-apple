// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistribute.h"

@interface MSACDistributeUIUtil : NSObject

/**
 * Finds and returns an active window to be used as a presentation anchor.
 *
 * @return Presentation anchor.
 */
+ (ASPresentationAnchor)getPresentationAnchor API_AVAILABLE(ios(13));

@end
