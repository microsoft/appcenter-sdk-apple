// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACDistribute.h"
#import "MSACDistributeIngestion.h"
#import "MSACIngestionProtocol.h"
#import "MSACReleaseDetailsPrivate.h"
#import "MSACServiceInternal.h"

/**
 * For Swift Package Manager the name of the bundle resource consists of [Package name]_[Resource name].
 */
#ifdef SWIFTPM_MODULE_BUNDLE
#define APP_CENTER_DISTRIBUTE_BUNDLE_NAME @"App Center_AppCenterDistribute"
#else
#define APP_CENTER_DISTRIBUTE_BUNDLE_NAME @"AppCenterDistributeResources"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * The keychain key for update token.
 */
static NSString *const kMSACUpdateTokenKey = @"MSUpdateToken";

@interface MSACDistribute () <MSACServiceInternal>

/**
 * An install URL that is used when the SDK needs to acquire update token.
 */
@property(nonatomic, copy) NSString *installUrl;

/**
 * An API url that is used to get release details from backend.
 */
@property(nonatomic, copy) NSString *apiUrl;

/**
 * An ingestion instance that is used to send a request for new release to the backend.
 */
@property(nonatomic, nullable) MSACDistributeIngestion *ingestion;

@end

NS_ASSUME_NONNULL_END
