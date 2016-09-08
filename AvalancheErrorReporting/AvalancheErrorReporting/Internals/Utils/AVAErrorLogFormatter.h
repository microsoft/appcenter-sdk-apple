
#import <Foundation/Foundation.h>

@class AVAAppleErrorLog;
@class AVAPLCrashReport;

/**
 *  Error logging error domain
 */
typedef NS_ENUM(NSInteger, AVABinaryImageType) {
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

+ (AVAAppleErrorLog *)errorLogFromCrashReport:(AVAPLCrashReport *)report;

@end
