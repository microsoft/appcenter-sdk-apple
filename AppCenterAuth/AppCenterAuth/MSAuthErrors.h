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
typedef NS_ENUM(NSInteger, MSACAuthError) {

  // Service.
  MSACAuthErrorServiceDisabled = 100,

  // SignIn.
  MSACAuthErrorPreviousSignInRequestInProgress = 200,
  MSACAuthErrorInterruptedByAnotherOperation = 201,
  MSACAuthErrorSignInNotConfigured = 202,
  MSACAuthErrorSignInConfigNotValid = 203,
  MSACAuthErrorSignInDownloadConfigFailed = 204,

  // Connection.
  MSACAuthErrorNoConnection = 300
};

NS_ASSUME_NONNULL_END
