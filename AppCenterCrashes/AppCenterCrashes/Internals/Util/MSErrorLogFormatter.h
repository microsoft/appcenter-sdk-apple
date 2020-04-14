// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAppleErrorLog;
@class MSErrorReport;
@class PLCrashReport;

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

+ (MSAppleErrorLog *)errorLogFromCrashReport:(PLCrashReport *)report;

+ (MSErrorReport *)errorReportFromCrashReport:(PLCrashReport *)report;

+ (MSErrorReport *)errorReportFromLog:(MSAppleErrorLog *)errorLog;

@end
