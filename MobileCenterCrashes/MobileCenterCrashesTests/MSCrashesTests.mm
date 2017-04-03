#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAppleErrorLog.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesTestUtil.h"
#import "MSException.h"
#import "MSMockCrashesDelegate.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSWrapperExceptionManagerInternal.h"
#import "MSCrashesUtil.h"

@class MSMockCrashesDelegate;

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSCrashesServiceName = @"Crashes";
static NSString *const kMSFatal = @"fatal";

@interface MSCrashes ()

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation;

- (void)startCrashProcessing;

- (void)channel:(id)channel willSendLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

@end

@interface MSCrashesTests : XCTestCase<MSCrashesDelegate>

@property(nonatomic) MSCrashes *sut;

@property BOOL shouldProcessErrorReportCalled;
@property BOOL willSendErrorReportCalled;
@property BOOL didSucceedSendingErrorReportCalled;
@property BOOL didFailSendingErrorReportCalled;

@end

@implementation MSCrashesTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSCrashes new];
}

- (void)tearDown {
  [super tearDown];
  [self.sut deleteAllFromCrashesDirectory];
  [MSCrashesTestUtil deleteAllFilesInDirectory:[self.sut.logBufferDir path]];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  
  // When
  // An instance of MSCrashes is created.

  // Then
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.logBufferDir, notNilValue());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityHigh].size() == 20);
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityDefault].size() == 20);
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityBackground].size() == 20);

  // Creation of buffer files is done asynchronously, we need to give it some time to create the files.
  [NSThread sleepForTimeInterval:0.05];
  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
    NSString *dirPath = [[self.sut.logBufferDir path] stringByAppendingFormat:@"/%ld/", static_cast<long>(priority)];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL];
    assertThat(files, hasCountOf(20));
  }
}

- (void)testStartingManagerInitializesPLCrashReporter {

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.plCrashReporter, notNilValue());
}

- (void)testStartingManagerWritesLastCrashReportToCrashesDir {
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));
}

- (void)testSettingDelegateWorks {
  
  // When
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  [MSCrashes setDelegate:delegateMock];
  
  // Then
  XCTAssertNotNil([MSCrashes sharedInstance].delegate);
  XCTAssertEqual([MSCrashes sharedInstance].delegate, delegateMock);
}

- (void)testDelegateMethodsAreCalled {
  
  // If
  self.shouldProcessErrorReportCalled = false;
  self.willSendErrorReportCalled = false;
  self.didSucceedSendingErrorReportCalled = false;
  self.didFailSendingErrorReportCalled = false;
  
  // When
  [[MSCrashes sharedInstance] setDelegate:self];
  MSAppleErrorLog *errorLog = [MSAppleErrorLog new];
  [[MSCrashes sharedInstance] channel:nil willSendLog:errorLog];
  [[MSCrashes sharedInstance] channel:nil didSucceedSendingLog:errorLog];
  [[MSCrashes sharedInstance] channel:nil didFailSendingLog:errorLog withError:nil];
  [[MSCrashes sharedInstance] shouldProcessErrorReport:nil];
  
  // Then
  XCTAssertTrue(self.shouldProcessErrorReportCalled);
  XCTAssertTrue(self.willSendErrorReportCalled);
  XCTAssertTrue(self.didSucceedSendingErrorReportCalled);
  XCTAssertTrue(self.didFailSendingErrorReportCalled);
}

- (void)testSettingUserConfirmationHandler {
  
  // When
  MSUserConfirmationHandler userConfirmationHandler = ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> * _Nonnull errorReports) { return NO; };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandler];
  
  // Then
  XCTAssertNotNil([MSCrashes sharedInstance].userConfirmationHandler);
  XCTAssertEqual([MSCrashes sharedInstance].userConfirmationHandler, userConfirmationHandler);
}

- (void)testCrashesDelegateWithoutImplementations {

  // When
  MSMockCrashesDelegate *delegateMock = OCMPartialMock([MSMockCrashesDelegate new]);
  [MSCrashes setDelegate:delegateMock];

  // Then
  assertThatBool([[MSCrashes sharedInstance] shouldProcessErrorReport:nil], isTrue());
  assertThatBool([[MSCrashes sharedInstance] delegateImplementsAttachmentCallback], isFalse());
}

- (void)testProcessCrashes {
  
  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));
  
  // When
  [MS_USER_DEFAULTS setObject:@YES forKey:@"MSUserConfirmation"];
  [[MSCrashes sharedInstance] startCrashProcessing];
  [MS_USER_DEFAULTS removeObjectForKey:@"MSUserConfirmation"];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));
  
  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));
  
  // When
  MSUserConfirmationHandler userConfirmationHandlerYES = ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> * _Nonnull errorReports) { return YES; };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandlerYES];
  [[MSCrashes sharedInstance] startCrashProcessing];
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
  [MSCrashes setUserConfirmationHandler:nil];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));
  
  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));
  
  // When
  MSUserConfirmationHandler userConfirmationHandlerNO = ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> * _Nonnull errorReports) { return NO; };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandlerNO];
  [[MSCrashes sharedInstance] startCrashProcessing];
  
  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));
}

- (void)testDeleteAllFromCrashesDirectory {

  // If
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_signal"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut deleteAllFromCrashesDirectory];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
}

- (void)testDeleteCrashReportsOnDisabled {

  // If
  id settingsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([settingsMock objectForKey:[OCMArg any]]).andReturn(@YES);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut setEnabled:NO];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:[self.sut.crashesDir path] error:nil].count, equalToLong(0));
}

- (void)testDeleteCrashReportsFromDisabledToEnabled {

  // If
  id settingsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([settingsMock objectForKey:[OCMArg any]]).andReturn(@NO);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut setEnabled:YES];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:[self.sut.crashesDir path] error:nil].count, equalToLong(0));
}

// FIXME: Crashes is getting way more logs than expected. Disable this functionality.
- (void)setupLogBufferWorks {

  // When
  // This is the directly after initialization.

  // Then
  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
    NSString *dirPath = [[self.sut.logBufferDir path] stringByAppendingFormat:@"/%ld/", static_cast<long>(priority)];

    NSArray *first = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL];
    XCTAssertTrue(first.count == 20);
    for (NSString *path in first) {
      unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
      XCTAssertTrue(fileSize == 0);
    }

    // When
    [self.sut setupLogBuffer];

    // Then
    NSArray *second = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL];
    for (int i = 0; i < 20; i++) {
      XCTAssertTrue([first[i] isEqualToString:second[i]]);
    }
  }
}

- (void)testCreateBufferFile {
  // When
  NSString *testName = @"afilename";
  NSString *priorityDirectory =
      [[self.sut.logBufferDir path] stringByAppendingFormat:@"/%ld/", static_cast<long>(MSPriorityDefault)];
  NSString *filePath =
      [priorityDirectory stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];
  [self.sut createBufferFileAtURL:[NSURL fileURLWithPath:filePath]];

  // Then
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);
}

- (void)testEmptyLogBufferFiles {
  // If
  NSString *testName = @"afilename";
  NSString *dataString = @"SomeBufferedData";
  NSData *someData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *priorityDirectory =
      [[self.sut.logBufferDir path] stringByAppendingFormat:@"/%ld/", static_cast<long>(MSPriorityHigh)];

  NSString *filePath =
      [priorityDirectory stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];

  [someData writeToFile:filePath options:NSDataWritingFileProtectionNone error:nil];

  // When
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);

  // Then
  unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
  XCTAssertTrue(fileSize == 16);
  [self.sut emptyLogBufferFiles];
  fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
  XCTAssertTrue(fileSize == 0);
}

- (void)testBufferIndexIncrementForAllPriorities {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING andPriority:MSPriorityHigh];

  // Then
  XCTAssertTrue([self crashesLogBufferCount:MSPriorityHigh] == 1);
}

- (void)testBufferIndexOverflowForAllPriorities {

  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {

    // When
    for (int i = 0; i < 20; i++) {
      MSLogWithProperties *log = [MSLogWithProperties new];
      [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING andPriority:static_cast<MSPriority>(priority)];
    }

    // Then
    XCTAssertTrue([self crashesLogBufferCount:static_cast<MSPriority>(priority)] == 20);

    // When
    MSLogWithProperties *log = [MSLogWithProperties new];
    [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING andPriority:static_cast<MSPriority>(priority)];
    NSNumberFormatter *timestampFormatter = [[NSNumberFormatter alloc] init];
    timestampFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    int indexOfLatestObject = 0;
    NSNumber *oldestTimestamp;
    for (auto it = msCrashesLogBuffer[static_cast<MSPriority>(priority)].begin(),
              end = msCrashesLogBuffer[static_cast<MSPriority>(priority)].end();
         it != end; ++it) {
      NSNumber *bufferedLogTimestamp = [timestampFormatter
          numberFromString:[NSString stringWithCString:it->timestamp.c_str() encoding:NSUTF8StringEncoding]];

      // Remember the timestamp if the log is older than the previous one or the initial one.
      if (!oldestTimestamp || oldestTimestamp.doubleValue > bufferedLogTimestamp.doubleValue) {
        oldestTimestamp = bufferedLogTimestamp;
        indexOfLatestObject = it - msCrashesLogBuffer[static_cast<MSPriority>(priority)].begin();
      }
    }

    // Then
    XCTAssertTrue([self crashesLogBufferCount:static_cast<MSPriority>(priority)] == 20);
    XCTAssertTrue(indexOfLatestObject == 1);

    // When
    for (int i = 0; i < 50; i++) {
      MSLogWithProperties *aLog = [MSLogWithProperties new];
      [self.sut onEnqueuingLog:aLog withInternalId:MS_UUID_STRING andPriority:static_cast<MSPriority>(priority)];
    }

    indexOfLatestObject = 0;
    oldestTimestamp = nil;
    for (auto it = msCrashesLogBuffer[static_cast<MSPriority>(priority)].begin(),
              end = msCrashesLogBuffer[static_cast<MSPriority>(priority)].end();
         it != end; ++it) {
      NSNumber *bufferedLogTimestamp = [timestampFormatter
          numberFromString:[NSString stringWithCString:it->timestamp.c_str() encoding:NSUTF8StringEncoding]];

      // Remember the timestamp if the log is older than the previous one or the initial one.
      if (!oldestTimestamp || oldestTimestamp.doubleValue > bufferedLogTimestamp.doubleValue) {
        oldestTimestamp = bufferedLogTimestamp;
        indexOfLatestObject = it - msCrashesLogBuffer[static_cast<MSPriority>(priority)].begin();
      }
    }

    // Then
    XCTAssertTrue([self crashesLogBufferCount:static_cast<MSPriority>(priority)] == 20);
    XCTAssertTrue(indexOfLatestObject == 11);
  }
}


- (void)testBufferIndexOnPersistingLog {
  
  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  NSString *uuid1 = MS_UUID_STRING;
  NSString *uuid2 = MS_UUID_STRING;
  NSString *uuid3 = MS_UUID_STRING;
  [self.sut onEnqueuingLog:log withInternalId:uuid1 andPriority:MSPriorityHigh];
  [self.sut onEnqueuingLog:log withInternalId:uuid2 andPriority:MSPriorityHigh];
  [self.sut onEnqueuingLog:log withInternalId:uuid3 andPriority:MSPriorityHigh];
  
  // Then
  XCTAssertTrue([self crashesLogBufferCount:MSPriorityHigh] == 3);
  
  // When
  [self.sut onFinishedPersistingLog:nil withInternalId:uuid1 andPriority:MSPriorityHigh];
  
  // Then
  XCTAssertTrue([self crashesLogBufferCount:MSPriorityHigh] == 2);
  
  // When
  [self.sut onFailedPersistingLog:nil withInternalId:uuid2 andPriority:MSPriorityHigh];
  
  // Then
  XCTAssertTrue([self crashesLogBufferCount:MSPriorityHigh] == 1);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([[MSCrashes sharedInstance] initializationPriority] == MSInitializationPriorityMax);
}

- (void)testEnablingMachExceptionWorks {
  // Then
  XCTAssertFalse([[MSCrashes sharedInstance] isMachExceptionHandlerEnabled]);

  // When
  [MSCrashes enableMachExceptionHandler];

  // Then
  XCTAssertTrue([[MSCrashes sharedInstance] isMachExceptionHandlerEnabled]);

  // Then
  XCTAssertFalse([self.sut isMachExceptionHandlerEnabled]);

  // When
  [self.sut setEnableMachExceptionHandler:YES];

  // Then
  XCTAssertTrue([self.sut isMachExceptionHandlerEnabled]);
}

- (void)testBufferDirectoryWorks {

  // When
  NSString *expected = [[[MSCrashesUtil logBufferDir] path]
      stringByAppendingString:[NSString stringWithFormat:@"/%ld", static_cast<long>(MSPriorityBackground)]];
  NSString *actual = [[self.sut bufferDirectoryForPriority:MSPriorityBackground] path];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);

  // When
  expected = [[[MSCrashesUtil logBufferDir] path]
      stringByAppendingString:[NSString stringWithFormat:@"/%ld", static_cast<long>(MSPriorityDefault)]];
  actual = [[self.sut bufferDirectoryForPriority:MSPriorityDefault] path];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);

  // When
  expected = [[[MSCrashesUtil logBufferDir] path]
      stringByAppendingString:[NSString stringWithFormat:@"/%ld", static_cast<long>(MSPriorityHigh)]];
  actual = [[self.sut bufferDirectoryForPriority:MSPriorityHigh] path];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);
}

- (void)testCrashesServiceNameIsCorrect {
  XCTAssertEqual([MSCrashes serviceName], kMSCrashesServiceName);
}

- (void)testWrapperCrashCallback {
  
  // If
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  
  // When
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  MSWrapperExceptionManager *manager = [MSWrapperExceptionManager sharedInstance];
  manager.wrapperException = exception;
  [MSCrashesTestUtil deleteAllFilesInDirectory:[MSWrapperExceptionManager directoryPath]];
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [MSCrashes wrapperCrashCallback];
  
  // Then
  NSArray *first = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MSWrapperExceptionManager directoryPath] error:NULL];
  XCTAssertTrue(first.count == 1);
}

- (void)testAbstractErrorLogSerialization {
  MSAbstractErrorLog *log = [MSAbstractErrorLog new];

  // When
  NSDictionary *serializedLog = [log serializeToDictionary];

  // Then static_cast<NSObject *>
  XCTAssertFalse([static_cast<NSNumber*>([serializedLog objectForKey:kMSFatal]) boolValue]);

  // If
  log.fatal = NO;

  // When
  serializedLog = [log serializeToDictionary];

  // Then
  XCTAssertFalse([static_cast<NSNumber*>([serializedLog objectForKey:kMSFatal]) boolValue]);

  // If
  log.fatal = YES;

  // When
  serializedLog = [log serializeToDictionary];

  // Then
  XCTAssertTrue([static_cast<NSNumber*>([serializedLog objectForKey:kMSFatal]) boolValue]);
}

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  (void)crashes;
  (void)errorReport;
  self.shouldProcessErrorReportCalled = true;
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  (void)crashes;
  (void)errorReport;
  self.willSendErrorReportCalled = true;
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  (void)crashes;
  (void)errorReport;
  self.didSucceedSendingErrorReportCalled = true;
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  (void)crashes;
  (void)errorReport;
  (void)error;
  self.didFailSendingErrorReportCalled = true;
}

- (NSInteger)crashesLogBufferCount:(MSPriority)priority {
  NSInteger bufferCount = 0;
  for (auto it = msCrashesLogBuffer[priority].begin(), end = msCrashesLogBuffer[priority].end(); it != end; ++it) {
    if (!it->internalId.empty()) {
      bufferCount++;
    }
  }
  return bufferCount;
}

@end
