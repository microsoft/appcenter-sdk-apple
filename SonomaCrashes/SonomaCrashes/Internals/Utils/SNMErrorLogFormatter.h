
#import <Foundation/Foundation.h>

@class SNMAppleErrorLog;
@class SNMPLCrashReport;
@class SNMErrorReport;

/**
 *  Error logging error domain
 */
typedef NS_ENUM(NSInteger, SNMBinaryImageType) {
  /**
   *  App binary
   */
  SNMBinaryImageTypeAppBinary,
  /**
   *  App provided framework
   */
  SNMBinaryImageTypeAppFramework,
  /**
   *  Image not related to the app
   */
  SNMBinaryImageTypeOther
};

@interface SNMErrorLogFormatter : NSObject

+ (SNMAppleErrorLog *)errorLogFromCrashReport:(SNMPLCrashReport *)report;

+ (SNMErrorReport *) createErrorReportFrom:(SNMPLCrashReport *)report;

@end
