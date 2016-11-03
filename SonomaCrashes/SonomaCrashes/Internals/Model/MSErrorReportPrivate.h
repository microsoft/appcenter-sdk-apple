/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSErrorReport.h"

extern NSString *const __attribute__((unused)) kMSErrorReportKillSignal;

@interface MSErrorReport ()

- (instancetype)initWithErrorId:(NSString *)errorId
                    reporterKey:(NSString *)reporterKey
                         signal:(NSString *)signal
                  exceptionName:(NSString *)exceptionName
                exceptionReason:(NSString *)exceptionReason
                   appStartTime:(NSDate *)appStartTime
                   appErrorTime:(NSDate *)appErrorTime
                         device:(MSDevice *)device
           appProcessIdentifier:(NSUInteger)appProcessIdentifier;

@end
