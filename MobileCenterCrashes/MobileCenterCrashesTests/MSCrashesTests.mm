
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAppleErrorLog.h"
#import "MSChannelDelegate.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesTestUtil.h"
#import "MSMockCrashesDelegate.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSUtil.h"

@class MSMockCrashesDelegate;

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSCrashesTests : XCTestCase

@property(nonatomic, strong) MSCrashes *sut;

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
  [MSCrashesTestUtil deleteAllFilesInDirectory:self.sut.logBufferDir];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.logBufferDir, notNilValue());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
  XCTAssertTrue(msCrashesLogBuffer.size() == 20);

  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.sut.logBufferDir error:NULL];
  XCTAssertTrue(files.count == 20);
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
  OCMStub([settingsMock objectForKey:[OCMArg any]]).andReturn([NSNumber numberWithBool:YES]);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut setEnabled:NO];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:self.sut.crashesDir error:nil].count, equalToLong(0));
}

- (void)testDeleteCrashReportsFromDisabledToEnabled {

  // If
  MSUserDefaults *settingsMock = OCMClassMock([MS_USER_DEFAULTS class]);
  OCMStub([settingsMock objectForKey:[OCMArg any]]).andReturn([NSNumber numberWithBool:NO]);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut setEnabled:YES];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:self.sut.crashesDir error:nil].count, equalToLong(0));
}

- (void)testSetupLogBufferWorks {

  // If

  // When
  // This is the directly after initialization.

  // Then
  NSArray *first = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.sut.logBufferDir error:NULL];
  XCTAssertTrue(first.count == 20);
  for (NSString *path in first) {
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    XCTAssertTrue(fileSize == 0);
  }

  // When
  [self.sut setupLogBuffer];
  NSArray *second = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.sut.logBufferDir error:NULL];
  for (int i = 0; i < 20; i++) {
    XCTAssertTrue([first[i] isEqualToString:second[i]]);
  }
}

- (void)testCreateBufferFile {
  // When
  NSString *testName = @"afilename";
  [self.sut createBufferFileWithName:testName];

  // Then
  NSString *filePath =
      [self.sut.logBufferDir stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);
}

- (void)testEmptyLogBufferFiles {
  // If
  NSString *testName = @"afilename";
  NSString *dataString = @"SomeBufferedData";
  NSData *someData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *filePath =
      [self.sut.logBufferDir stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];

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

- (void)testBufferIndexIncrement {
  // When
  MSAppleErrorLog *log = [MSAppleErrorLog new];
  [self.sut onProcessingLog:log withPriority:MSPriorityHigh];

  // Then
  XCTAssertTrue(self.sut.bufferIndex == 1);
}

- (void)testBufferIndexOverflow {
  // When
  for (int i = 0; i < 20; i++) {
    MSAppleErrorLog *log = [MSAppleErrorLog new];
    [self.sut onProcessingLog:log withPriority:MSPriorityHigh];
  }
  // Then
  XCTAssertTrue(self.sut.bufferIndex == 20);

  // When
  MSAppleErrorLog *log = [MSAppleErrorLog new];
  [self.sut onProcessingLog:log withPriority:MSPriorityHigh];

  // Then
  XCTAssertTrue(self.sut.bufferIndex == 1);
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

@end
