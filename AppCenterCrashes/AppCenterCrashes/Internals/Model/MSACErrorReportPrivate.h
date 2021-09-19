// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACErrorReport.h"

static NSString *const kMSACErrorReportKillSignal = @"SIGKILL";

@class MSACThread, MSACBinary;

@interface MSACErrorReport ()

- (instancetype)initWithErrorId:(NSString *)errorId
                    reporterKey:(NSString *)reporterKey
                         signal:(NSString *)signal
                  exceptionName:(NSString *)exceptionName
                exceptionReason:(NSString *)exceptionReason
                   appStartTime:(NSDate *)appStartTime
                   appErrorTime:(NSDate *)appErrorTime
                       codeType:(NSString *)codeType
                       archName:(NSString *)archName
                applicationPath:(NSString *)applicationPath
                        threads:(NSArray<MSACThread *> *)threads
                       binaries:(NSArray<MSACBinary *> *)binaries
                         device:(MSACDevice *)device
           appProcessIdentifier:(NSUInteger)appProcessIdentifier;

@end
