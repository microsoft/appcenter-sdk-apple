#import "SNMSessionTracker.h"
#import "SNMSessionTrackerHelper.h"
#import "Sonoma+Internal.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

NSTimeInterval const kSNMTestSessionTimeout = 1.5;

@interface SNMSessionTrackerTests : XCTestCase

@property(nonatomic) SNMSessionTracker *sut;

@end

@implementation SNMSessionTrackerTests

- (void)setUp {
  [super setUp];

  _sut = [[SNMSessionTracker alloc] init];
  [_sut setSessionTimeout:kSNMTestSessionTimeout];
  [_sut start];

  [SNMSessionTrackerHelper simulateDidEnterBackgroundNotification];
  [NSThread sleepForTimeInterval:0.1];
  [SNMSessionTrackerHelper simulateWillEnterForegroundNotification];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testSession {

  NSString *expectedSid;

  // Verify the creation of sid and device log
  {
    expectedSid = _sut.sessionId;

    XCTAssertNotNil(expectedSid);
  }

  // Verify reuse of the same session id on next get
  {
    NSString *sid = _sut.sessionId;

    XCTAssertEqual(expectedSid, sid);
  }
}

// Apps is in foreground for longer than the timeout time, still same session
- (void)testLongForegroundSession {
  NSString *expectedSid = _sut.sessionId;
  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  // Wait for longer than timeout in foreground
  [NSThread sleepForTimeInterval:kSNMTestSessionTimeout + 1];

  NSString *sid = _sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testShortBackgroundSession {
  NSString *expectedSid = _sut.sessionId;
  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  // Enter background
  [SNMSessionTrackerHelper simulateDidEnterBackgroundNotification];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kSNMTestSessionTimeout - 1];

  // Enter foreground
  [SNMSessionTrackerHelper simulateWillEnterForegroundNotification];

  NSString *sid = _sut.sessionId;

  XCTAssertEqual(expectedSid, sid);
}

- (void)testLongBackgroundSession {
  NSString *expectedSid = _sut.sessionId;
  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [SNMSessionTrackerHelper simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kSNMTestSessionTimeout + 1];

  // Enter foreground
  [SNMSessionTrackerHelper simulateWillEnterForegroundNotification];

  NSString *sid = _sut.sessionId;
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testLongBackgroundSessionWithSessionTrackingStopped {

  // Stop session tracking
  [_sut stop];

  NSString *expectedSid = _sut.sessionId;
  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [SNMSessionTrackerHelper simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kSNMTestSessionTimeout + 1];

  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];

  NSString *sid = _sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testTooLongInBackground {
  NSString *expectedSid = _sut.sessionId;

  XCTAssertNotNil(expectedSid);

  [SNMSessionTrackerHelper simulateWillEnterForegroundNotification];

  [NSThread sleepForTimeInterval:1];
  // Enter background
  [SNMSessionTrackerHelper simulateDidEnterBackgroundNotification];

  // mock a log creation while app is in background
  _sut.lastCreatedLogTime = [NSDate date];

  [NSThread sleepForTimeInterval:kSNMTestSessionTimeout + 1];

  //_sut.lastCreatedLogTime = [NSDate date];

  NSString *sid = _sut.sessionId;
  XCTAssertNotEqual(expectedSid, sid);
}

@end
