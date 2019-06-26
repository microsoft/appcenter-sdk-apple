// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Data.ErrorDomain";

#pragma mark - General

// Error codes.
typedef NS_ENUM(NSInteger, MSACDataError) { // System framework errors.
  MSACDataErrorInvalidClassCode = 101,
  MSACDataErrorJSONSerializationFailed = 102,

  // Document errors.
  MSACDataErrorDocumentNotFound = 200,
  MSACDataErrorCachedToken = 201,
  MSACDataErrorLocalDocumentExpired = 202,
  MSACDataErrorDocumentIdMissing = 203,
  MSACDataErrorInvalidPartition = 204,
  MSACDataErrorInvalidTokenExchangeResponse = 205,
  MSACDataErrorUnsupportedOperation = 206,
  MSACDataErrorDocumentIdInvalid = 207,
  MSACDataErrorNextDocumentPageUnavailable = 208,

  // Network errors
  MSACDataErrorHTTPError = 300,
  MSACDataErrorUnableToGetToken = 301
};

// Error descriptions.
static NSString const *kMSACDataInvalidClassDesc = @"Provided class does not conform to serialization protocol (MSSerializableDocument).";
static NSString const *kMSACDataCosmosDbErrorResponseDesc = @"Unexpected error while talking to CosmosDB.";
static NSString const *kMSACDocumentCreationDesc = @"Can't create document.";
static NSString const *kMSACDataErrorDocumentIdInvalidDesc = @"Invalid document ID.";
static NSString const *kMSACDataErrorNextDocumentPageUnavailableDesc = @"Can't retrieve the next page when the device is offline.";

NS_ASSUME_NONNULL_END
