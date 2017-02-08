/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@import Foundation;

@class MSAppleErrorLog;
@class MSPLCrashReport;
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

+ (MSAppleErrorLog *)errorLogFromCrashReport:(MSPLCrashReport *)report;

+ (MSErrorReport *)errorReportFromCrashReport:(MSPLCrashReport *)report;

+ (MSErrorReport *)errorReportFromLog:(MSAppleErrorLog *)errorLog;

@end
