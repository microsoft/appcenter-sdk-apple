// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterErrors.h"
#import <Foundation/Foundation.h>

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
NS_ENUM(NSInteger){kMSACIdentityErrorServiceDisabled = -420000, kMSACIdentityErrorPreviousSignInRequestInProgress = -420001,
                   kMSACIdentityErrorSignInBackgroundOrNotConfigured = -420002, kMSACIdentityErrorSignInWhenNoConnection = -420003};

NS_ASSUME_NONNULL_END
