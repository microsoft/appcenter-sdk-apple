// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MSDictionaryUtils)

/**
 * Test if an object is a dictionary that has a key of a given type.
 *
 * @param key The key to look for in the dictionary reference.
 * @param keyType The expected key type.
 */
- (BOOL)isDictionaryWithKey:(NSString *)key keyType:(Class)keyType;

@end

NS_ASSUME_NONNULL_END
