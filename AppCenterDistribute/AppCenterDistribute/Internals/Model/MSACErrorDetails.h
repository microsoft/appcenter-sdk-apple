// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error code string for no_releases_for_user.
 * TODO: The SDK is only interested in no_releases_for_user code so far.
 * It needs to be an enum type if the SDK starts handling multiple error codes.
 */
static NSString const *kMSACErrorCodeNoReleasesForUser = @"no_releases_for_user";

/**
 * Error code string when no releases were found for the application.
 */
static NSString const *kMSACErrorCodeNoReleasesFound = @"not_found";

/**
 * Details of an error response.
 */
@interface MSACErrorDetails : NSObject

/**
 * Error code.
 * enum:
 *   not_found
 *   release_not_found
 *   no_upload_resource
 *   release_not_uploaded
 *   filter_error
 *   internal_server_error
 *   not_supported
 *   no_releases_for_app
 *   no_releases_for_user
 *   bad_request
 *   distribution_group_not_found
 *   not_implemented
 *   partially_deleted
 *   package_not_found
 *   package_not_uploaded
 *   no_packages_for_app
 */
@property(nonatomic, copy, readwrite) NSString *code;

/**
 * Error message.
 */
@property(nonatomic, copy, readwrite) NSString *message;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs.
 *
 * @return  A new instance.
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary;

/**
 * Checks if the values are valid.
 *
 * @return YES if it is valid, otherwise NO.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
