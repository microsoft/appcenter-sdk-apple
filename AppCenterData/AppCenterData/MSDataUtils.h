// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDataUtils : NSObject

/**
 * Deserialize string into an `NSDate`.
 *
 * @param dateString String to deserialize.
 *
 * @return `NSDate` instance if `dateString` contains a valid date; nil otherwise.
 */
+ (NSDate *)deserializeDate:(NSString *)dateString;

/**
 * Serialize an `NSDate` into a ISO 8601 formatted string.
 *
 * @param date Date to serialize.
 *
 * @return `NSString` instance representing the date in ISO 8601 format.
 */
+ (NSString *)serializeDate:(NSDate *)date;

@end
