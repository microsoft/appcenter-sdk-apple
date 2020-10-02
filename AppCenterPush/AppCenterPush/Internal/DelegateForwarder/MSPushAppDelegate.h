// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACAppDelegateForwarder.h"
#import "MSCustomPushApplicationDelegate.h"

@interface MSPushAppDelegate : NSObject <MSCustomPushApplicationDelegate>

@end

#pragma mark - Forwarding

@interface MSACAppDelegateForwarder (MSPush) <MSCustomPushApplicationDelegate>

@end
