// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterErrors.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

/**
 * Error domain for Identity.
 */
static NSString *const kMSIdentityErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Identity.ErrorDomain";

/**
 * Error description key for Identity.
 */
static NSString *const kMSIdentityErrorDescriptionKey = @"MSIdentityErrorDescriptionKey";

#pragma mark - Error Codes

/**
 * Error code for Identity.
 */
NS_ENUM(NSInteger){kMSIdentityErrorServiceDisabled = -420000, kMSIdentityErrorPreviousSignInRequestInProgress = -420001,
  kMSIdentityErrorSignInBackgroundOrNotConfigured = -420002, kMSIdentityErrorSignInWhenNoConnection = -420003};

NS_ASSUME_NONNULL_END
