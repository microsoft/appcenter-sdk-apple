
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
#import "MSCrashesUtil.h"

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

// FIXME: Crashes is getting way more logs than expected. Disable this functionality.
- (void)newInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.logBufferDir, notNilValue());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityHigh].size() == 20);
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityDefault].size() == 20);
  XCTAssertTrue(msCrashesLogBuffer[MSPriorityBackground].size() == 20);

  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
    NSString *dirPath = [self.sut.logBufferDir stringByAppendingFormat:@"/%ld/", priority];
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

// FIXME: Crashes is getting way more logs than expected. Disable this functionality.
- (void)setupLogBufferWorks {

  // When
  // This is the directly after initialization.

  // Then
  for (NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
    NSString *dirPath = [self.sut.logBufferDir stringByAppendingFormat:@"/%ld/", priority];

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
  [self.sut createBufferFileWithName:testName forPriority:MSPriorityHigh];
  
  // Then
  NSString *priorityDirectory = [self.sut.logBufferDir stringByAppendingFormat:@"/%ld/", MSPriorityHigh];

  NSString *filePath =
      [priorityDirectory stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);
}

// FIXME: Crashes is getting way more logs than expected. Disable this functionality.
- (void)emptyLogBufferFiles {
  // If
  NSString *testName = @"afilename";
  NSString *dataString = @"SomeBufferedData";
  NSData *someData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *priorityDirectory = [self.sut.logBufferDir stringByAppendingFormat:@"/%ld/", MSPriorityHigh];

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
  MSAppleErrorLog *log = [MSAppleErrorLog new];
  [self.sut onProcessingLog:log withPriority:MSPriorityHigh];

  // Then
  XCTAssertTrue([self.sut.bufferIndex[@(MSPriorityHigh)] isEqualToNumber:@1]);
}

- (void)testBufferIndexOverflowForAllPriorities {
  
  for(NSInteger priority = 0; priority < kMSPriorityCount; priority++) {
  
  // When
  for (int i = 0; i < 20; i++) {
    MSAppleErrorLog *log = [MSAppleErrorLog new];
    [self.sut onProcessingLog:log withPriority:(MSPriority)priority];
  }
  // Then
  XCTAssertTrue([self.sut.bufferIndex[@(priority)] isEqualToNumber:@20]);

  // When
  MSAppleErrorLog *log = [MSAppleErrorLog new];
  [self.sut onProcessingLog:log withPriority:(MSPriority)priority];

  // Then
  XCTAssertTrue([self.sut.bufferIndex[@(priority)] isEqualToNumber:@1]);
  
  // When
  for (int i = 0; i < 50; i++) {
    MSAppleErrorLog *log = [MSAppleErrorLog new];
    [self.sut onProcessingLog:log withPriority:(MSPriority)priority];
  }
  // Then
  XCTAssertTrue([self.sut.bufferIndex[@(priority)] isEqualToNumber:@11]);
  
  // When
  [self.sut onProcessingLog:log withPriority:(MSPriority)priority];
  
  // Then
  XCTAssertTrue([self.sut.bufferIndex[@(priority)] isEqualToNumber:@12]);
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
  NSString *expected = [[MSCrashesUtil logBufferDir] stringByAppendingString:[NSString stringWithFormat:@"/%ld/", MSPriorityBackground]];
  NSString *actual = [self.sut bufferDirectoryForPriority:MSPriorityBackground];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);

  // When
  expected = [[MSCrashesUtil logBufferDir] stringByAppendingString:[NSString stringWithFormat:@"/%ld/", MSPriorityDefault]];
  actual = [self.sut bufferDirectoryForPriority:MSPriorityDefault];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);

  // When
  expected = [[MSCrashesUtil logBufferDir] stringByAppendingString:[NSString stringWithFormat:@"/%ld/", MSPriorityHigh]];
  actual = [self.sut bufferDirectoryForPriority:MSPriorityHigh];

  // Then
  XCTAssertTrue([expected isEqualToString:actual]);
}

@end
