#import <Foundation/Foundation.h>

@class MSAppleErrorLog;
@class MSErrorReport;
@class MSPLCrashReport;

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
