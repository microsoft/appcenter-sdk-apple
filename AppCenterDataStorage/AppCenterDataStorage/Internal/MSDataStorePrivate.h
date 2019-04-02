// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base URL for HTTP for token exchange.
 */
static NSString *const kMSDefaultApiUrl = @"https://api.appcenter.ms/v0.1";

@interface MSDataStore () <MSAuthTokenContextDelegate>

/**
 * A flag that indicates offline mode is on or off.
 */
@property(atomic) BOOL offlineMode;

/**
 * The dispatch queue that cache operations will be performed with.
 */
@property dispatch_queue_t dataStoreDispatchQueue;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
