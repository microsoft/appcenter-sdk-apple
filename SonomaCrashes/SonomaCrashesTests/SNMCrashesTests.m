#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMCrashesPrivate.h"
#import "SNMCrashTestHelper.h"

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
  [self.sut startFeature];
  
  // Then
  assertThat(self.sut.plCrashReporter, notNilValue());
}

- (void)testStartingManagerWritesLastCrashReportToCrashesDir {
  [self.sut deleteAllFromCrashesDirectory];
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatBool([SNMCrashTestHelper copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  
  // When
  [self.sut startFeature];
  
  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));
}








@end
