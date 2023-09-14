// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static NSString *const kMSMainStoryboardName = @"SasquatchMac";
static NSString *const kMSUserIdKey = @"userId";
static NSString *const kMSACDataResidencyRegion = @"kMSACDataResidencyRegion";
static NSString *const kMSLogUrl = @"logUrl";
static NSString *const kMSAppSecret = @"appSecret";
static NSString *const kMSLogTag = @"[SasquatchMac]";
static NSString *const kMSManualSessionTracker = @"kMSManualSessionTracker";
static NSString *const kMSUserConfirmationKey = @"MSAppCenterCrashesUserConfirmation";
static NSString *const kSASCustomizedUpdateAlertKey = @"kSASCustomizedUpdateAlertKey";
static NSString *const kMSChildTransmissionTargetTokenKey = @"kMSChildTransmissionTargetToken";
static NSString *const kMSStorageMaxSizeKey = @"storageMaxSize";
static NSString *const kMSStartTargetKey = @"startTarget";

#ifdef SQLITE_DEFAULT_PAGE_SIZE
static int const kMSStoragePageSize = SQLITE_DEFAULT_PAGE_SIZE;
#else
static int const kMSStoragePageSize = 4096;
#endif

@interface Constants : NSObject

@property(class, readonly, nonnull) NSString *kMSTargetToken1;
@property(class, readonly, nonnull) NSString *kMSTargetToken2;
@property(class, readonly, nonnull) NSString *kMSSwiftRuntimeTargetToken;
@property(class, readonly, nonnull) NSString *kMSSwiftTargetToken;
@property(class, readonly, nonnull) NSString *kMSSwiftAppSecret;
@property(class, readonly, nonnull) NSString *kMSObjcAppSecret;
@property(class, readonly, nonnull) NSString *kMSObjCTargetToken;
@property(class, readonly, nonnull) NSString *kMSObjCRuntimeTargetToken;

@end
