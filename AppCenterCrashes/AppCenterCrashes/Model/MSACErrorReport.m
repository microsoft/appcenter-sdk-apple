// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACErrorReport.h"
#import "MSACErrorReportPrivate.h"

static NSString *const kMSACIncidentIdentifier = @"incidentIdentifier";
static NSString *const kMSACReporterKey = @"reporterKey";
static NSString *const kMSACSignal = @"signal";
static NSString *const kMSACExceptionName = @"exceptionName";
static NSString *const kMSACExceptionReason = @"exceptionReason";
static NSString *const kMSACAppStartTime = @"appStartTime";
static NSString *const kMSACAppErrorTime = @"appErrorTime";
static NSString *const kMSACDevice = @"device";
static NSString *const kMSACThreads = @"threads";
static NSString *const kMSACBinaries = @"binaries";
static NSString *const kMSACArchName = @"archName";
static NSString *const kMSACCodeType = @"codeType";
static NSString *const kMSACApplicationPath = @"applicationPath";
static NSString *const kMSACAppProcessIdentifier = @"appProcessIdentifier";

@interface MSACErrorReport ()

@property(nonatomic, copy) NSString *signal;

@end

@implementation MSACErrorReport

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
           appProcessIdentifier:(NSUInteger)appProcessIdentifier {

  if ((self = [super init])) {
    _incidentIdentifier = errorId;
    _reporterKey = reporterKey;
    _signal = signal;
    _exceptionName = exceptionName;
    _exceptionReason = exceptionReason;
    _appStartTime = appStartTime;
    _appErrorTime = appErrorTime;
    _codeType = codeType;
    _archName = archName;
    _applicationPath = applicationPath;
    _threads = threads;
    _binaries = binaries;
    _device = device;
    _appProcessIdentifier = appProcessIdentifier;
  }
  return self;
}

- (BOOL)isAppKill {
  BOOL result = NO;

  if (self.signal && [[self.signal uppercaseString] isEqualToString:kMSACErrorReportKillSignal])
    result = YES;

  return result;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.incidentIdentifier) {
    dict[kMSACIncidentIdentifier] = self.incidentIdentifier;
  }
  if (self.reporterKey) {
    dict[kMSACReporterKey] = self.reporterKey;
  }
  if (self.signal) {
    dict[kMSACSignal] = self.signal;
  }
  if (self.exceptionName) {
    dict[kMSACExceptionName] = self.exceptionName;
  }
  if (self.exceptionReason) {
    dict[kMSACExceptionReason] = self.exceptionReason;
  }
  if (self.appStartTime) {
    dict[kMSACAppStartTime] = self.appStartTime;
  }
  if (self.appErrorTime) {
    dict[kMSACAppErrorTime] = self.appErrorTime;
  }
  if (self.codeType) {
    dict[kMSACCodeType] = self.codeType;
  }
  if (self.archName) {
    dict[kMSACArchName] = self.archName;
  }
  if (self.applicationPath) {
    dict[kMSACApplicationPath] = self.applicationPath;
  }
  if (self.threads) {
    dict[kMSACThreads] = self.threads;
  }
  if (self.binaries) {
    dict[kMSACBinaries] = self.binaries;
  }
  if (self.device) {
    dict[kMSACDevice] = self.device;
  }
  if (self.appProcessIdentifier) {
    dict[kMSACAppProcessIdentifier] = [NSString stringWithFormat:@"%lu", (unsigned long)self.appProcessIdentifier];
  }
  return dict;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@", [self serializeToDictionary]];
}

@end
