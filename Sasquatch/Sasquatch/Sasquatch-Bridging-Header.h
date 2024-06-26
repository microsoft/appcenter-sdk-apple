// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

//
//  Use this file to import your target's public headers that you would like to
//  expose to Swift.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "CrashLib.h"

#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "MSACErrorAttachmentLog.h"
#import "MSACEventPropertiesInternal.h"
#import "MSACExceptionModel.h"
#import "MSEventFilter.h"
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
#endif
