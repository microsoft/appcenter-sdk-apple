// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define MS_APP_CENTER_BASE_DOMAIN @"com.Microsoft.AppCenter."

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"ErrorDomain";

#pragma mark - General

// Error codes.
NS_ENUM(NSInteger){kMSACLogInvalidContainerErrorCode = 1, kMSACCanceledErrorCode = 2};

// Error descriptions.
static NSString const *kMSACLogInvalidContainerErrorDesc = @"Invalid log container.";
static NSString const *kMSACCanceledErrorDesc = @"The operation was canceled.";

#pragma mark - Connection

// Error codes.
NS_ENUM(NSInteger){kMSACConnectionPausedErrorCode = 100, kMSACConnectionHttpErrorCode = 101};

// Error descriptions.
static NSString const *kMSACConnectionHttpErrorDesc = @"An HTTP error occured.";
static NSString const *kMSACConnectionPausedErrorDesc = @"Canceled, connection paused with log deletion.";

// Error user info keys.
static NSString const *kMSACConnectionHttpCodeErrorKey = MS_APP_CENTER_BASE_DOMAIN "HttpCodeKey";

NS_ASSUME_NONNULL_END
