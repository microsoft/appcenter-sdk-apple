/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorReport.h"

extern NSString *const __attribute__((unused)) kSNMErrorReportKillSignal;

@interface SNMErrorReport ()

- (instancetype)initWithErrorId:(NSString *)errorId
                               reporterKey:(NSString *)reporterKey
                                    signal:(NSString *)signal
                             exceptionName:(NSString *)exceptionName
                           exceptionReason:(NSString *)exceptionReason
                              appStartTime:(NSDate *)appStartTime
                                 crashTime:(NSDate *)crashTime
                                 osVersion:(NSString *)osVersion
                                   osBuild:(NSString *)osBuild
                                appVersion:(NSString *)appVersion
                                  appBuild:(NSString *)appBuild
                      appProcessIdentifier:(NSUInteger)appProcessIdentifier;

@end
