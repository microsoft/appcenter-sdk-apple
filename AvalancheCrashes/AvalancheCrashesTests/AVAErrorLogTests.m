#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleBinary.h"
#import "AVAAppleErrorLog.h"
#import "AVAAppleException.h"
#import "AVAAppleThread.h"
#import "AvalancheHub+Internal.h"

@interface AVAErrorLogTests : XCTestCase

@end

@implementation AVAErrorLogTests

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  AVAAppleErrorLog *sut = [self errorLog];
  NSTimeInterval createTime = [[NSDate date] timeIntervalSince1970];
  NSNumber *tOffset = @(createTime);
  sut.toffset = tOffset;

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.crashId));
  assertThat(actual[@"processId"], equalTo(sut.processId));
  assertThat(actual[@"processName"], equalTo(sut.processName));
  assertThat(actual[@"parentProcessId"], equalTo(sut.parentProcessId));
  assertThat(actual[@"parentProcessName"], equalTo(sut.parentProcessName));
  assertThat(actual[@"errorThreadId"], equalTo(sut.errorThreadId));
  assertThat(actual[@"errorThreadName"], equalTo(sut.errorThreadName));
  assertThat(actual[@"fatal"], equalTo(sut.fatal));
  assertThat(actual[@"appLaunchTOffset"], equalTo(sut.appLaunchTOffset));
  assertThat(actual[@"cpuType"], equalTo(sut.cpuType));
  assertThat(actual[@"cpuSubType"], equalTo(sut.cpuSubType));
  assertThat(actual[@"applicationPath"], equalTo(sut.applicationPath));
  assertThat(actual[@"osExceptionType"], equalTo(sut.osExceptionType));
  assertThat(actual[@"osExceptionCode"], equalTo(sut.osExceptionCode));
  assertThat(actual[@"osExceptionAddress"], equalTo(sut.osExceptionAddress));
  assertThat(actual[@"exceptionType"], equalTo(sut.exceptionType));
  assertThat(actual[@"exceptionReason"], equalTo(sut.exceptionReason));
  assertThat(actual[@"registers"], equalTo(sut.registers));
  // TODO add assert for binaries and threads?
  assertThat(actual[@"type"], equalTo(@"error"));
  assertThat(actual[@"device"], notNilValue());
  NSTimeInterval seralizedToffset = [actual[@"toffset"] integerValue];
  NSTimeInterval actualToffset = [[NSDate date] timeIntervalSince1970] - createTime;
  assertThat(@(seralizedToffset), lessThan(@(actualToffset)));
  assertThat(actual[@"properties"], equalTo(sut.properties));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  AVAAppleErrorLog *sut = [self errorLog];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAAppleErrorLog class]));

  AVAAppleErrorLog *actualError = actual;
  assertThat(actualError.crashId, equalTo(sut.crashId));
  assertThat(actualError.processId, equalTo(sut.processId));
  assertThat(actualError.processName, equalTo(sut.processName));
  assertThat(actualError.parentProcessId, equalTo(sut.parentProcessId));
  assertThat(actualError.parentProcessName, equalTo(sut.parentProcessName));
  assertThat(actualError.errorThreadId, equalTo(sut.errorThreadId));
  assertThat(actualError.errorThreadName, equalTo(sut.errorThreadName));
  assertThat(actualError.fatal, equalTo(sut.fatal));
  assertThat(actualError.appLaunchTOffset, equalTo(sut.appLaunchTOffset));
  assertThat(actualError.cpuType, equalTo(sut.cpuType));
  assertThat(actualError.cpuSubType, equalTo(sut.cpuSubType));
  assertThat(actualError.applicationPath, equalTo(sut.applicationPath));
  assertThat(actualError.osExceptionType, equalTo(sut.osExceptionType));
  assertThat(actualError.osExceptionCode, equalTo(sut.osExceptionCode));
  assertThat(actualError.osExceptionAddress, equalTo(sut.osExceptionAddress));
  assertThat(actualError.exceptionType, equalTo(sut.exceptionType));
  assertThat(actualError.exceptionReason, equalTo(sut.exceptionReason));
  assertThatInteger(actualError.registers.count, equalToInteger(1));
  assertThatInteger(actualError.threads.count, equalToInteger(1));
  assertThat(actualError.type, equalTo(sut.type));
  assertThat(actualError.sid, equalTo(sut.sid));
  assertThat(actualError.device, equalTo(sut.device));
  assertThat(actualError.toffset, equalTo(sut.toffset));
  assertThat(actualError.properties, equalTo(sut.properties));
}

#pragma mark - Helper

- (AVAAppleErrorLog *)errorLog {
  AVAAppleErrorLog *errorLog = [AVAAppleErrorLog new];
  NSString *crashId = @"crashId";
  NSNumber *processId = @(12);
  NSString *processName = @"processName";
  NSString *parentProcessName = @"parentProcessName";
  NSNumber *parentProcessId = @(13);
  NSNumber *errorThreadId = @(4);
  NSString *errorThreadName = @"errorThreadName";
  NSNumber *fatal = @(4);
  NSNumber *appLaunchTOffset = @(134);
  NSNumber *cpuType = @(2);
  NSNumber *cpuSubType = @(3);
  NSString *applicationPath = @"applicationPath";
  NSString *osExceptionType = @"osExceptionType";
  NSString *osExceptionCode = @"osExceptionCode";
  NSString *osExceptionAddress = @"osExceptionAddress";
  NSString *exceptionType = @"exceptionType";
  NSString *exceptionReason = @"exceptionReason";
  NSDictionary *registers = @{ @"Register1" : @"ValueRegister1" };

  NSArray<AVAAppleThread *> *threads = [NSArray arrayWithObject:[AVAAppleThread new]];
  NSArray<AVAAppleBinary *> *binaries = [NSArray arrayWithObject:[AVAAppleBinary new]];
  AVADevice *device = [AVADevice new];
  
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  NSDictionary *properties = @{ @"Key" : @"Value" };

  errorLog.crashId = crashId;
  errorLog.processId = processId;
  errorLog.processName = processName;
  errorLog.parentProcessId = parentProcessId;
  errorLog.parentProcessName = parentProcessName;
  errorLog.errorThreadId = errorThreadId;
  errorLog.errorThreadName = errorThreadName;
  errorLog.fatal = fatal;
  errorLog.appLaunchTOffset = appLaunchTOffset;
  errorLog.cpuType = cpuType;
  errorLog.cpuSubType = cpuSubType;
  errorLog.applicationPath = applicationPath;
  errorLog.osExceptionType = osExceptionType;
  errorLog.osExceptionCode = osExceptionCode;
  errorLog.osExceptionAddress = osExceptionAddress;
  errorLog.exceptionType = exceptionType;
  errorLog.exceptionReason = exceptionReason;
  errorLog.registers = registers;
  errorLog.threads = threads;
  errorLog.binaries = binaries;
  errorLog.sid = sessionId;
  errorLog.device = device;
  errorLog.toffset = tOffset;
  errorLog.properties = properties;

  return errorLog;
}

@end
