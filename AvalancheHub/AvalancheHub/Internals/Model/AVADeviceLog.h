/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAbstractLog.h"
#import <Foundation/Foundation.h>

@protocol AVADeviceLog
@end

@interface AVADeviceLog : AVAAbstractLog

@property(nonatomic) NSString* sdkVersion;
/* Device model (example: iPad2,3).
 */
@property(nonatomic) NSString* model;
/* Device manufacturer (example: HTC).
 */
@property(nonatomic) NSString* oemName;
/* OS name (example: iOS).
 */
@property(nonatomic) NSString* osName;
/* OS version (example: 9.3.0).
 */
@property(nonatomic) NSString* osVersion;
/* API level when applicable like in Android (example: 15).  [optional]
 */
@property(nonatomic) NSNumber* osApiLevel;
/* Language code (example: en_US).
 */
@property(nonatomic) NSString* locale;
/* The offset in minutes from UTC for the device time zone, including daylight savings time.
 */
@property(nonatomic) NSNumber* timeZoneOffset;
/* Screen size of the device in pixels (example: 640x480).
 */
@property(nonatomic) NSString* screenSize;
/* Application version name.
 */
@property(nonatomic) NSString* appVersion;
/* Carrier name (for mobile devices).  [optional]
 */
@property(nonatomic) NSString* carrierName;
/* Carrier country code (for mobile devices).  [optional]
 */
@property(nonatomic) NSString* carrierCountry;

@end
