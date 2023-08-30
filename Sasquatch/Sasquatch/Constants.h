// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static NSString *const kSASCustomizedUpdateAlertKey = @"kSASCustomizedUpdateAlertKey";
static NSString *const kSASAutomaticCheckForUpdateDisabledKey = @"kSASAutomaticCheckForUpdateDisabledKey";
static NSString *const kMSUpdateTrackKey = @"kMSUpdateTrackKey";
static NSString *const kMSChildTransmissionTargetTokenKey = @"kMSChildTransmissionTargetToken";
static NSString *const kMSTransmissionIterval = @"kMSTransmissionIterval";
static NSString *const kMSManualSessionTracker = @"kMSManualSessionTracker";
static NSString *const kMSACDataResidencyRegion = @"kMSACDataResidencyRegion";

static NSString *const kMSStartTargetKey = @"startTarget";
static NSString *const kMSStorageMaxSizeKey = @"storageMaxSize";
static NSNotificationName const kUpdateAnalyticsResultNotification = @"updateAnalyticsResult";
static NSString *const kMSUserIdKey = @"userId";
static NSString *const kMSLogUrl = @"logUrl";
static NSString *const kMSTimeToLive = @"timeToLive";
static NSString *const kMSAppSecret = @"appSecret";
static NSString *const kMSUserIdentity = @"userIdentity";
static NSString *const kMSUserConfirmationKey = @"MSAppCenterCrashesUserConfirmation";

#ifdef SQLITE_DEFAULT_PAGE_SIZE
static int const kMSStoragePageSize = SQLITE_DEFAULT_PAGE_SIZE;
#else
static int const kMSStoragePageSize = 4096;
#endif

static NSString *const kMSIntLogUrl = @"https://in-integration.dev.avalanch.es";
static NSString *const kMSIntConfigUrl = @"https://config-integration.dev.avalanch.es";
static NSString *const kMSIntApiUrl = @"https://api-gateway-core-integration.dev.avalanch.es/v0.1";
static NSString *const kMSIntInstallUrl = @"https://install.portal-server-core-integration.dev.avalanch.es";

static NSString *const kMSABaseUrl = @"https://login.live.com/oauth20_";
static NSString *const kMSARedirectEndpoint = @"desktop.srf";
static NSString *const kMSAAuthorizeEndpoint = @"authorize.srf";
static NSString *const kMSATokenEndpoint = @"token.srf";
static NSString *const kMSAClientIdParam = @"&client_id=06181c2a-2403-437f-a490-9bcb06f85281";
static NSString *const kMSARedirectParam = @"redirect_uri=https://login.live.com/oauth20_desktop.srf";
static NSString *const kMSASignOutEndpoint = @"logout.srf";
static NSString *const kMSARefreshParam = @"&grant_type=refresh_token&refresh_token=";
static NSString *const kMSARefreshTokenParam = @"refresh_token";
static NSString *const kMSAScopeParam = @"&scope=service::events.data.microsoft.com::MBI_SSL";

@interface Constants : NSObject

@property(class, readonly, nonnull) NSString *kMSTargetToken1;
@property(class, readonly, nonnull) NSString *kMSTargetToken2;
@property(class, readonly, nonnull) NSString *kMSSwiftTargetToken;
@property(class, readonly, nonnull) NSString *kMSSwiftRuntimeTargetToken;
@property(class, readonly, nonnull) NSString *kMSObjCTargetToken;
@property(class, readonly, nonnull) NSString *kMSObjCRuntimeTargetToken;
@property(class, readonly, nonnull) NSString *kMSPuppetAppSecret;
@property(class, readonly, nonnull) NSString *kMSObjcAppSecret;
@property(class, readonly, nonnull) NSString *kMSSwiftCombinedAppSecret;
@property(class, readonly, nonnull) NSString *kMSSwiftAppSecret;
@property(class, readonly, nonnull) NSString *kMSSwiftCatalystAppSecret;

@end
