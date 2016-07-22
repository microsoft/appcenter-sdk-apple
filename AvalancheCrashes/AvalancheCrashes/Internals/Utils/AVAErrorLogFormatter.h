
#import <Foundation/Foundation.h>

@class AVAErrorLog;
@class PLCrashReport;

@interface AVAErrorLogFormatter : NSObject

+ (AVAErrorLog *)errorLogFromCrashReport:(PLCrashReport *)report;


@end
