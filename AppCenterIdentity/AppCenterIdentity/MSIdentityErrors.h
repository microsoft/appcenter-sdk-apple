// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

/**
 * Error domain for Identity.
 */
static NSString *const kMSACIdentityErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Identity.ErrorDomain";

#pragma mark - Error Codes

/**
 * Error code for Identity.
 */
NS_ENUM(NSInteger){MSACIdentityErrorServiceDisabled = -420000, MSACIdentityErrorPreviousSignInRequestInProgress = -420001,
                   MSACIdentityErrorSignInBackgroundOrNotConfigured = -420002, MSACIdentityErrorSignInWhenNoConnection = -420003};

NS_ASSUME_NONNULL_END
