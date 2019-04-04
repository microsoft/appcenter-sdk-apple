// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "NSObject+MSDictionaryUtils.h"

@implementation NSObject (MSDictionaryUtils)

- (BOOL)isDictionaryWithKey:(NSString *)key keyType:(Class)keyType {

  // Validate the reference is a dictionary.
  if (!self || ![self isKindOfClass:[NSDictionary class]]) {
    return false;
  }

  // Validate the reference has the expected key.
  NSObject *keyObject = [(NSDictionary *)self objectForKey:key];
  if (!keyObject) {
    return false;
  }

  // Validate the key object is of the expected type.
  return [keyObject isKindOfClass:keyType];
}

@end
