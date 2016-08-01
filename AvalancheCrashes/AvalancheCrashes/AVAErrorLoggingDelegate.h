#import <Foundation/Foundation.h>

@class AVAPublicErrorLog;
@class AVACrashes;
@class AVAErrorAttachment;

@protocol AVAErrorLoggingDelegate <NSObject>

@optional

- (AVAErrorAttachment *) attachmentForErrorReporting: (AVACrashes *)crashes forErrorReport:(AVAPublicErrorLog *)errorLog;

- (void)errorReportingWillSend:(AVACrashes *)crashes;

- (BOOL)errorReporting:(AVACrashes *)crashes considerErrorReport:(AVAPublicErrorLog *)errorLog;

- (void)errorReporting:(AVACrashes *)crashes didFailSendingErrorLog:(AVAPublicErrorLog *)errorLog;

- (void)errorReporting:(AVACrashes *)crashes didSucceedSendingErrorLog:(AVAPublicErrorLog *)errorLog;


@end