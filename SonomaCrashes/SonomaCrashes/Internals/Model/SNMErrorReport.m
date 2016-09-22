/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorReport.h"
#import "SNMErrorReportPrivate.h"

NSString *const kSNMErrorReportKillSignal = @"SIGKILL";

@implementation SNMErrorReport


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
                      appProcessIdentifier:(NSUInteger)appProcessIdentifier {

  if ((self = [super init])) {
    _incidentIdentifier = errorId;
    _reporterKey = reporterKey;
    _signal = signal;
    _exceptionName = exceptionName;
    _exceptionReason = exceptionReason;
    _appStartTime = appStartTime;
    _crashTime = crashTime;
    _osVersion = osVersion;
    _osBuild = osBuild;
    _appVersion = appVersion;
    _appBuild = appBuild;
    _appProcessIdentifier = appProcessIdentifier;
  }
  return self;
}


- (BOOL)isAppKill {
  BOOL result = NO;

  if (_signal && [[_signal uppercaseString] isEqualToString:kSNMErrorReportKillSignal])
    result = YES;

  return result;
}

@end
