/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Details of an error response.
 */
@interface MSErrorDetails : NSObject

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

@end

NS_ASSUME_NONNULL_END
