// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

/**
 * Error domain for Auth.
 */
static NSString *const kMSACAuthErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Auth.ErrorDomain";

#pragma mark - Error Codes

/**
 * Error code for Auth.
 */
NS_ENUM(NSInteger){// System framework errors
                   MSACAuthErrorServiceDisabled = 101,

                   // Sign in errors
                   MSACAuthErrorPreviousSignInRequestInProgress = 201, MSACAuthErrorSignInConfigNotValid = 202,
                   MSACAuthErrorSignInWhenNoConnection = 203, MSACAuthErrorSignInDownloadConfigFailed = 204,
                   MSACAuthErrorSignInBackgroundOrNotConfigured = 205};

NS_ASSUME_NONNULL_END
