/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"

@import Foundation;

@protocol MSSessionTrackerDelegate <NSObject>

@required

- (void)sessionTracker:(id)sessionTracker processLog:(id <MSLog>)log withPriority:(MSPriority)priority;

@end
