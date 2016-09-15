/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol SNMSerializableObject <NSCoding>

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (NSMutableDictionary *)serializeToDictionary;

@end
