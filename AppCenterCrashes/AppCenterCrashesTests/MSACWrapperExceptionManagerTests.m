// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACCrashes.h"
#import "MSACCrashesUtil.h"
#import "MSACLogger.h"
#import "MSACTestFrameworks.h"
#import "MSACUtility+File.h"
#import "MSACUtility.h"
#import "MSACWrapperException.h"
#import "MSACWrapperExceptionManagerInternal.h"
#import "MSACWrapperExceptionModel.h"
#import "PLCrashReporter.h"
#import "MSACWrapperExceptionModel.h"
#import "MSACHandledErrorLog.h"
#import "MSACExceptionModel.h"
#import "MSACStackFrame.h"
#import "MSACDevice.h"
#import "MSACUtility.h"
#import "MSACAppleErrorLog.h"
#import "MSACBinary.h"
#import "MSACThread.h"
#import "MSACWrapperException.h"
#import "MSACErrorAttachmentLog.h"
#import "MSACErrorReport.h"

// Copied from MSACWrapperExceptionManager.m
static NSString *const kMSACLastWrapperExceptionFileName = @"last_saved_wrapper_exception";

@interface MSACWrapperExceptionManagerTests : XCTestCase
@end

// Expose private methods for use in tests
@interface MSACWrapperExceptionManager ()

+ (MSACWrapperException *)loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename;

@end

@implementation MSACWrapperExceptionManagerTests

- (void)setUp {
  [super setUp];
  NSArray *allowedClassesArray = @[[MSACAppleErrorLog class], [NSDate class], [MSACDevice class], [MSACThread class], [MSACWrapperException class], [MSACAbstractErrorLog class], [MSACHandledErrorLog class], [MSACWrapperExceptionModel class], [MSACWrapperExceptionModel class], [MSACStackFrame class], [MSACBinary class], [MSACErrorAttachmentLog class], [MSACErrorReport class], [MSACWrapperSdk class], [NSUUID class], [NSDictionary class], [NSArray class], [NSNull class], [MSACThread class], [NSMutableData class], [MSACExceptionModel class]];
              
  [MSACUtility addAllowedClasses: allowedClassesArray];
}

#pragma mark - Housekeeping

- (void)tearDown {
  [super tearDown];
  [MSACWrapperExceptionManager deleteAllWrapperExceptions];
}

#pragma mark - Helper

- (MSACWrapperExceptionModel *)getModelException {
  MSACWrapperExceptionModel *exception = [[MSACWrapperExceptionModel alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData *)getData {
  return [@"some string" dataUsingEncoding:NSUTF8StringEncoding];
}

- (MSACWrapperException *)getWrapperException {
  MSACWrapperException *wrapperException = [[MSACWrapperException alloc] init];
  wrapperException.modelException = [self getModelException];
  wrapperException.exceptionData = [self getData];
  wrapperException.processId = @(rand());
  return wrapperException;
}

- (void)assertWrapperException:(MSACWrapperException *)wrapperException isEqualToOther:(MSACWrapperException *)other {

  // Test that the exceptions are the same.
  assertThat(other.processId, equalTo(wrapperException.processId));
  assertThat(other.exceptionData, equalTo(wrapperException.exceptionData));
  assertThat(other.modelException, equalTo(wrapperException.modelException));

  // The exception field.
  assertThat(other.modelException.type, equalTo(wrapperException.modelException.type));
  assertThat(other.modelException.message, equalTo(wrapperException.modelException.message));
  assertThat(((MSACWrapperExceptionModel *)other.modelException).wrapperSdkName,
             equalTo(((MSACWrapperExceptionModel *)wrapperException.modelException).wrapperSdkName));
}

#pragma mark - Test

- (void)testSaveAndLoadWrapperExceptionWorks {

  // If
  MSACWrapperException *wrapperException = [self getWrapperException];

  // When
  [MSACWrapperExceptionManager saveWrapperException:wrapperException];
  MSACWrapperException *loadedException =
      [MSACWrapperExceptionManager loadWrapperExceptionWithBaseFilename:kMSACLastWrapperExceptionFileName];

  // Then
  XCTAssertNotNil(loadedException);
  [self assertWrapperException:wrapperException isEqualToOther:loadedException];
}

- (void)testSaveWrapperExceptionAndCrashReportWhenCrashReporterIsNull {

  // If.
  id mockUtility = OCMClassMock([MSACUtility class]);

  // When.
  [MSACWrapperExceptionManager setCrashReporter:nil];
  MSACWrapperException *wrapperException = [self getWrapperException];

  // Then.
  OCMReject([mockUtility createDirectoryAtURL:OCMOCK_ANY]);

  // When.
  [MSACWrapperExceptionManager saveWrapperExceptionAndCrashReport:wrapperException];

  // Stop mocking.
  [mockUtility stopMocking];
}

- (void)testSaveWrapperExceptionAndCrashReportWhenDirectoryWasNotCreated {

  // If.
  id mockUtility = OCMClassMock([MSACUtility class]);
  OCMStub(ClassMethod([mockUtility createDirectoryAtURL:OCMOCK_ANY])).andReturn(NO);

  // Mock crashReporter.
  id mockCrashReporter = OCMClassMock([PLCrashReporter class]);
  NSString *mockPath = @"file://mock/live_report.plcrash";
  NSData *mockData = [NSData new];
  OCMStub([mockCrashReporter crashReportPath]).andReturn(mockPath);
  OCMStub([mockCrashReporter generateLiveReport]).andReturn(mockData);

  // When.
  [MSACWrapperExceptionManager setCrashReporter:mockCrashReporter];
  MSACWrapperException *wrapperException = [self getWrapperException];

  // Then.
  OCMReject([mockUtility createFileAtPath:OCMOCK_ANY contents:OCMOCK_ANY attributes:OCMOCK_ANY]);

  // When.
  [MSACWrapperExceptionManager saveWrapperExceptionAndCrashReport:wrapperException];

  // Stop mocking.
  [mockUtility stopMocking];
  [mockCrashReporter stopMocking];
}

- (void)testSaveWrapperExceptionAndCrashReportWhenFailedToCreateFile {

  // If.
  id mockUtility = OCMClassMock([MSACUtility class]);
  OCMStub(ClassMethod([mockUtility createDirectoryAtURL:OCMOCK_ANY])).andReturn(YES);
  OCMStub(ClassMethod([mockUtility createFileAtPath:OCMOCK_ANY contents:OCMOCK_ANY attributes:OCMOCK_ANY])).andReturn(NO);

  // Mock crashReporter.
  id mockCrashReporter = OCMClassMock([PLCrashReporter class]);
  NSString *mockPath = @"file://mock/live_report.plcrash";
  NSData *mockData = [NSData new];
  OCMStub([mockCrashReporter crashReportPath]).andReturn(mockPath);
  OCMStub([mockCrashReporter generateLiveReport]).andReturn(mockData);

  // Remove file if it exists
  [[NSFileManager defaultManager] removeItemAtPath:mockPath error:nil];

  // When.
  [MSACWrapperExceptionManager setCrashReporter:mockCrashReporter];
  MSACWrapperException *wrapperException = [self getWrapperException];
  [MSACWrapperExceptionManager saveWrapperExceptionAndCrashReport:wrapperException];

  // Then.
  XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:mockPath]);

  // Stop mocking.
  [mockUtility stopMocking];
  [mockCrashReporter stopMocking];
}

- (void)testSaveWrapperExceptionAndCrashReport {

  // If.
  id mockUtility = OCMClassMock([MSACUtility class]);
  OCMStub(ClassMethod([mockUtility createDirectoryAtURL:OCMOCK_ANY])).andReturn(YES);
  OCMStub(ClassMethod([mockUtility createFileAtPath:OCMOCK_ANY contents:OCMOCK_ANY attributes:OCMOCK_ANY])).andReturn(YES);

  // Mock crashReporter.
  id mockCrashReporter = OCMClassMock([PLCrashReporter class]);
  NSString *mockPath = @"file://mock/live_report.plcrash";
  NSData *mockData = [NSData new];
  OCMStub([mockCrashReporter crashReportPath]).andReturn(mockPath);
  OCMStub([mockCrashReporter generateLiveReport]).andReturn(mockData);

  // When.
  [MSACWrapperExceptionManager setCrashReporter:mockCrashReporter];
  MSACWrapperException *wrapperException = [self getWrapperException];
  [MSACWrapperExceptionManager saveWrapperExceptionAndCrashReport:wrapperException];

  // Then.
  OCMVerify([mockUtility createFileAtPath:mockPath contents:mockData attributes:nil]);
  OCMVerify([mockUtility createFileAtPathComponent:OCMOCK_ANY withData:OCMOCK_ANY atomically:YES forceOverwrite:YES]);

  // Stop mocking.
  [mockUtility stopMocking];
  [mockCrashReporter stopMocking];
}

- (void)testSaveCorrelateWrapperExceptionWhenExists {

  // If
  int numReports = 4;
  NSMutableArray *mockReports = [NSMutableArray new];
  for (int i = 0; i < numReports; ++i) {
    id reportMock = OCMPartialMock([MSACErrorReport new]);
    OCMStub([reportMock appProcessIdentifier]).andReturn(i);
    OCMStub([reportMock incidentIdentifier]).andReturn([[NSUUID UUID] UUIDString]);
    [mockReports addObject:reportMock];
  }
  MSACErrorReport *report = mockReports[(NSUInteger)(rand() % numReports)];
  MSACWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = @([report appProcessIdentifier]);

  // When
  [MSACWrapperExceptionManager saveWrapperException:wrapperException];
  [MSACWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSACWrapperException *loadedException = [MSACWrapperExceptionManager loadWrapperExceptionWithUUIDString:[report incidentIdentifier]];

  // Then
  XCTAssertNotNil(loadedException);
  [self assertWrapperException:wrapperException isEqualToOther:loadedException];
}

- (void)testSaveCorrelateWrapperExceptionWhenNotExists {

  // If
  MSACWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = @4;
  NSMutableArray *mockReports = [NSMutableArray new];
  id reportMock = OCMPartialMock([MSACErrorReport new]);
  OCMStub([reportMock appProcessIdentifier]).andReturn(9);
  NSString *uuidString = [[NSUUID UUID] UUIDString];
  OCMStub([reportMock incidentIdentifier]).andReturn(uuidString);
  [mockReports addObject:reportMock];

  // When
  [MSACWrapperExceptionManager saveWrapperException:wrapperException];
  [MSACWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSACWrapperException *loadedException = [MSACWrapperExceptionManager loadWrapperExceptionWithUUIDString:uuidString];

  // Then
  XCTAssertNil(loadedException);
}

@end
