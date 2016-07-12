/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVALog

/**
 * Log type.
 */
@property(nonatomic) NSString *type;

/**
 * Corresponds to the number of milliseconds elapsed between the time the
 * request is sent and the time the log is emitted.
 */
@property(nonatomic) NSNumber *toffset;

/**
 * A session identifier is used to correlate logs together. A session is an
 * abstract concept in the API and
 * is not necessarily an analytics session, it can be used to only track
 * crashes.
 */
@property(nonatomic) NSString *sid;

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (BOOL)isValid;

/**
 * Indicates whether the property with the given name is optional.
 * If `propertyName` is optional, then return `YES`, otherwise return `NO`.
 * This method is used by `JSONModel`.
 */
+ (BOOL)propertyIsOptional:(NSString *)propertyName;

@required
/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (NSMutableDictionary *)serializeToDictionary;

@end
