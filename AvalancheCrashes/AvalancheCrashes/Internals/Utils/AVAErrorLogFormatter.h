
#import <Foundation/Foundation.h>

@class AVAErrorLog;
@class PLCrashReport;

/**
 *  Error logging error domain
 */
typedef NS_ENUM (NSInteger, AVABinaryImageType) {
  /**
   *  App binary
   */
  AVABinaryImageTypeAppBinary,
  /**
   *  App provided framework
   */
  AVABinaryImageTypeAppFramework,
  /**
   *  Image not related to the app
   */
  AVABinaryImageTypeOther
};

@interface AVAErrorLogFormatter : NSObject

+ (AVAErrorLog *)errorLogFromCrashReport:(PLCrashReport *)report;


@end
