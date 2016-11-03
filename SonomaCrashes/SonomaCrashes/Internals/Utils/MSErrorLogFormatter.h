/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class MSAppleErrorLog;
@class SNMPLCrashReport;
@class MSErrorReport;

/**
 *  Error logging error domain
 */
typedef NS_ENUM(NSInteger, MSBinaryImageType) {
  /**
   *  App binary
   */
  MSBinaryImageTypeAppBinary,
  /**
   *  App provided framework
   */
  MSBinaryImageTypeAppFramework,
  /**
   *  Image not related to the app
   */
  MSBinaryImageTypeOther
};

@interface MSErrorLogFormatter : NSObject

+ (MSAppleErrorLog *)errorLogFromCrashReport:(SNMPLCrashReport *)report;

+ (MSErrorReport *)errorReportFromCrashReport:(SNMPLCrashReport *)report;

+ (MSErrorReport *)errorReportFromLog:(MSAppleErrorLog *)errorLog;

@end
