#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMErrorReportPrivate.h"

@interface SNMErrorReportTests : XCTestCase

@end

@implementation SNMErrorReportTests

- (void)initializationWorks {
  NSString *incidentIdentifier = @"incidentIdentifier";
  NSString *reporterKey = @"reporterKey";
  NSString *signal = @"signal";
  NSString *exceptionName = @"exceptionName";
  NSString *exceptionReason = @"exceptionReason";
  NSDate *appStartTime = [NSDate new];
  NSDate *appCrashTime = [NSDate dateWithTimeIntervalSinceNow:20];
  NSString *osVersion = @"10.0.1";
  NSString *osBuild = @"14F33";
  NSString *appVersion = @"1.0-alpha1";
  NSString *appBuild = @"123";
  NSUInteger processIdentifier = 4;

  SNMErrorReport *sut = [[SNMErrorReport alloc] initWithIncidentIdentifier:incidentIdentifier
                                                               reporterKey:reporterKey
                                                                    signal:signal
                                                             exceptionName:exceptionName
                                                           exceptionReason:exceptionReason
                                                              appStartTime:appStartTime
                                                                 crashTime:appCrashTime
                                                                 osVersion:osVersion
                                                                   osBuild:osBuild
                                                                appVersion:appVersion
                                                                  appBuild:appBuild
                                                      appProcessIdentifier:processIdentifier];

  assertThat(sut, notNilValue());
  assertThat(sut.incidentIdentifier, equalTo(incidentIdentifier));
  assertThat(sut.reporterKey, equalTo(reporterKey));
  assertThat(sut.signal, equalTo(signal));
  assertThat(sut.exceptionName, equalTo(exceptionName));
  assertThat(sut.exceptionReason, equalTo(exceptionReason));
  assertThat(sut.appStartTime, equalTo(appStartTime));
  assertThat(sut.crashTime, equalTo(appCrashTime));
  assertThat(sut.osVersion, equalTo(osVersion));
  assertThat(sut.osBuild, equalTo(osBuild));
  assertThat(sut.appVersion, equalTo(appVersion));
  assertThat(sut.appBuild, equalTo(appBuild));
  assertThatUnsignedInteger(sut.appProcessIdentifier, equalToUnsignedInteger(processIdentifier));
}

@end
