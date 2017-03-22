#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAppleErrorLog.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesTestUtil.h"
#import "MSMockCrashesDelegate.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSCrashesUtil.h"

@class MSMockCrashesDelegate;

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSCrashesServiceName = @"Crashes";

@interface MSCrashesTests : XCTestCase

@property(nonatomic) MSCrashes *sut;

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
    XCTAssertTrue(files.count == 20);
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
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  [MSCrashes setDelegate:delegateMock];
  XCTAssertNotNil([MSCrashes sharedInstance].delegate);
  XCTAssertEqual([MSCrashes sharedInstance].delegate, delegateMock);
}

- (void)testCrashesDelegateWithoutImplementations {

  // When
  MSMockCrashesDelegate *delegateMock = OCMPartialMock([MSMockCrashesDelegate new]);
  [MSCrashes setDelegate:delegateMock];

  // Then
  assertThatBool([[MSCrashes sharedInstance] shouldProcessErrorReport:nil], isTrue());
  assertThatBool([[MSCrashes sharedInstance] delegateImplementsAttachmentCallback], isFalse());
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
  MSUserDefaults *settingsMock = OCMClassMock([MS_USER_DEFAULTS class]);
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
  MSUserDefaults *settingsMock = OCMClassMock([MS_USER_DEFAULTS class]);
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

  // If
  int buffercount = 0;

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING andPriority:MSPriorityHigh];
  for (auto it = msCrashesLogBuffer[MSPriorityHigh].begin(), end = msCrashesLogBuffer[MSPriorityHigh].end(); it != end;
       ++it) {
    if (!it->internalId.empty()) {
      buffercount += 1;
    }
  }

  // Then
  XCTAssertTrue(buffercount == 1);
}

- (void)testBufferIndexOverflowForAllPriorities {

  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {

    // When
    for (int i = 0; i < 20; i++) {
      MSLogWithProperties *log = [MSLogWithProperties new];
      [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING andPriority:static_cast<MSPriority>(priority)];
    }
    int buffercount = 0;
    for (auto it = msCrashesLogBuffer[static_cast<MSPriority>(priority)].begin(),
              end = msCrashesLogBuffer[static_cast<MSPriority>(priority)].end();
         it != end; ++it) {
      if (!it->internalId.empty()) {
        buffercount += 1;
      }
    }

    // Then
    XCTAssertTrue(buffercount == 20);

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
    XCTAssertTrue(buffercount == 20);
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
    XCTAssertTrue(buffercount == 20);
    XCTAssertTrue(indexOfLatestObject == 11);
  }
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

@end
