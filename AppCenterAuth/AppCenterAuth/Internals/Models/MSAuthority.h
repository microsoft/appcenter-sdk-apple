// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthority : NSObject

/**
 * The type of the authority
 */
@property(nonatomic, copy) NSString *type;

/**
 * The flag that indicates whether the authority is default or not.
 */
@property(nonatomic, getter=isDefaultAuthority) BOOL defaultAuthority;

/**
 * The authority URL of user flow.
 */
@property(nonatomic, copy) NSURL *authorityUrl;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains the key/value pairs for an authority.
 *
 * @return  A new instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

/**
 * Checks if authoritiy types.
 *
 * @return YES, if the authority types are valid.
 */
- (BOOL)isValidType;

/**
 * @param dictionary A dictionary that contains the key/value pairs for an authority.
 *
 * @return A new instance of Authority based on type.
 */
+ (MSAuthority *)authorityWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
