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
NS_ENUM(NSInteger){MSACAuthErrorServiceDisabled = -420000,           MSACAuthErrorPreviousSignInRequestInProgress = -420001,
                   MSACAuthErrorSignInConfigNotValid = -420002,      MSACAuthErrorSignInWhenNoConnection = -420003,
                   MSACAuthErrorSignInDownloadConfigFailed = -42004, MSACAuthErrorSignInBackgroundOrNotConfigured = -42005};

NS_ASSUME_NONNULL_END
