/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorReport.h"
#import "AVAErrorReportPrivate.h"

NSString *const kAVAErrorReportKillSignal = @"SIGKILL";

@implementation AVAErrorReport


- (instancetype)initWithIncidentIdentifier:(NSString *)incidentIdentifier
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
    _incidentIdentifier = incidentIdentifier;
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

  if (_signal && [[_signal uppercaseString] isEqualToString:kAVAErrorReportKillSignal])
    result = YES;

  return result;
}

@end
