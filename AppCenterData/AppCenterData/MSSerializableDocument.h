// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSSerializableDocument <NSObject>

@required

/**
 * Create a dictionary from the object.
 *
 * @return Dictionary representing the object. Keys must be instances of NSString
 * and values must be instances of NSArray, NSDictionary, NSString, NSNumber, NSArray, or NSNull.
 */
- (NSDictionary *)serializeToDictionary;

/**
 * Construct an object from a dictionary.
 *
 * @param dictionary Dictionary representing the object.
 *
 * @return An instance of the object.
 */
- (instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
