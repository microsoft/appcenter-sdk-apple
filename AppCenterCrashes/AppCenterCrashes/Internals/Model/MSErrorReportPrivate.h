// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSErrorReport.h"

static NSString *const kMSErrorReportKillSignal = @"SIGKILL";

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
