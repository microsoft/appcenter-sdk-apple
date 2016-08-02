#import <Foundation/Foundation.h>

@class AVAErrorReport;
@class AVACrashes;
@class AVAErrorAttachment;

@protocol AVAErrorLoggingDelegate <NSObject>

@optional

- (BOOL)errorReporting:(AVACrashes *)crashes shouldProcess:(AVAErrorReport *)errorReport;

- (AVAErrorAttachment *) attachmentWithErrorReporting: (AVACrashes *)crashes forErrorReport:(AVAErrorReport *)errorReport;

- (void)errorReportingWillSend:(AVACrashes *)crashes;


- (void)errorReporting:(AVACrashes *)crashes didFailSending:(AVAErrorReport *)errorReport withError:(NSError *)error;

- (void)errorReporting:(AVACrashes *)crashes didSucceedSending:(AVAErrorReport *)errorReport;


@end