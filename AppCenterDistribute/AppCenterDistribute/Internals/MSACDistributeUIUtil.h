//
//  MSACDistributeUIUtil.h
//  AppCenterDistribute
//
//  Created by Shadya Barada on 06.12.2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//
#import "MSACDistribute.h"

@interface MSACDistributeUIUtil : NSObject

/**
 * Finds and returns an active window to be used as a presentation anchor.
 *
 * @return Presentation anchor.
 */
+ (ASPresentationAnchor)getPresentationAnchor API_AVAILABLE(ios(13));

@end

