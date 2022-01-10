// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static NSString *const kMSMainStoryboardName = @"SasquatchMac";
static NSString *const kMSUserIdKey = @"userId";
static NSString *const kMSLogUrl = @"logUrl";
static NSString *const kMSAppSecret = @"appSecret";
static NSString *const kMSLogTag = @"[SasquatchMac]";
static NSString *const kMSManualSessionTracker = @"kMSManualSessionTracker";
static NSString *const kMSUserConfirmationKey = @"MSAppCenterCrashesUserConfirmation";

static NSString *const kSASCustomizedUpdateAlertKey = @"kSASCustomizedUpdateAlertKey";
static NSString *const kMSChildTransmissionTargetTokenKey = @"kMSChildTransmissionTargetToken";
static NSString *const kMSTargetToken1 = @"MAC_TARGET_TOKEN1";
static NSString *const kMSTargetToken2 = @"MAC_TARGET_TOKEN2";
static NSString *const kMSSwiftRuntimeTargetToken = @"MAC_SWIFT_RUNTIME_TARGET_TOKEN";

static NSString *const kMSStartTargetKey = @"startTarget";
static NSString *const kMSSwiftTargetToken = @"MAC_SWIFT_TARGET_TOKEN";
static NSString *const kMSSwiftAppSecret = @"MAC_SWIFT_APP_SECRET";
static NSString *const kMSObjcAppSecret = @"MAC_OBJC_APP_SECRET";
#if ACTIVE_COMPILATION_CONDITION_PUPPET
static NSString *const kMSObjCTargetToken = @"MAC_OBJC_TARGET_TOKEN_PUPPET";
static NSString *const kMSObjCRuntimeTargetToken = @"MAC_OBJC_RUNTIME_TARGET_TOKEN";
#else
static NSString *const kMSObjCTargetToken = @"MAC_OBJC_TARGET_TOKEN";
static NSString *const kMSObjCRuntimeTargetToken = @"MAC_OBJC_RUNTIME_TARGET_TOKEN";
#endif

static NSString *const kMSStorageMaxSizeKey = @"storageMaxSize";
#ifdef SQLITE_DEFAULT_PAGE_SIZE
static int const kMSStoragePageSize = SQLITE_DEFAULT_PAGE_SIZE;
#else
static int const kMSStoragePageSize = 4096;
#endif
