#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSCrashesDelegate.h"
#import "MSChannelDelegate.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesTestHelper.h"
#import "MSMockCrashesDelegate.h"

@class MSMockCrashesDelegate;

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
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
}

- (void)testStartingManagerInitializesPLCrashReporter {

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager))];

  // Then
  assertThat(self.sut.plCrashReporter, notNilValue());
}

- (void)testStartingManagerWritesLastCrashReportToCrashesDir {
  [self.sut deleteAllFromCrashesDirectory];
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatBool([MSCrashesTestHelper copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager))];

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
  assertThatBool([[MSCrashes sharedInstance] hasAttachment], isFalse());
}

@end
