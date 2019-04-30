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
NS_ENUM(NSInteger){MSACAuthErrorServiceDisabled = -420000, MSACAuthErrorPreviousSignInRequestInProgress = -420001,
                   MSACAuthErrorSignInBackgroundOrNotConfigured = -420002, MSACAuthErrorNoConnection = -420003,
                   MSACAuthErrorInterruptedByAnotherOperation = -420004, MSACAuthErrorSignInConfigNotValid = -420005,
                   MSACAuthErrorSignInDownloadConfigFailed = -420006};

NS_ASSUME_NONNULL_END
