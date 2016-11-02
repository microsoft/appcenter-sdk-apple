#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMCrashTestHelper.h"
#import "SNMCrashesDelegate.h"
#import "SNMCrashesPrivate.h"
#import "MSLogManager.h"

@interface SNMCrashesTests : XCTestCase

@property(nonatomic, strong) SNMCrashes *sut;

@end

@implementation SNMCrashesTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [SNMCrashes new];
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
  assertThatBool([SNMCrashTestHelper copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager))];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));
}

- (void)testSettingDelegateWorks {
  id<SNMCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(SNMCrashesDelegate));
  [SNMCrashes setDelegate:delegateMock];
  XCTAssertNotNil([SNMCrashes sharedInstance].delegate);
  XCTAssertEqual([SNMCrashes sharedInstance].delegate, delegateMock);
}

@end
