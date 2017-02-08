#import "MSAnalytics.h"
#import "MSConstants+Internal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerUtil.h"
#import "MSStartSessionLog.h"
#import "MobileCenter+Internal.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
@import XCTest;

NSTimeInterval const kMSTestSessionTimeout = 1.5;

@interface MSSessionTrackerTests : XCTestCase

@property(nonatomic) MSSessionTracker *sut;

@end

@implementation MSSessionTrackerTests

- (void)setUp {
  [super setUp];

  _sut = [[MSSessionTracker alloc] init];
  [_sut setSessionTimeout:kMSTestSessionTimeout];
  [_sut start];

  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];
  [NSThread sleepForTimeInterval:0.1];
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];
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
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  NSString *sid = _sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testShortBackgroundSession {
  NSString *expectedSid = _sut.sessionId;
  // mock a log creation
  _sut.lastCreatedLogTime = [NSDate date];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout - 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

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
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

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
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];

  NSString *sid = _sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testTooLongInBackground {
  NSString *expectedSid = _sut.sessionId;

  XCTAssertNotNil(expectedSid);

  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  [NSThread sleepForTimeInterval:1];
  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // mock a log creation while app is in background
  _sut.lastCreatedLogTime = [NSDate date];

  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  //_sut.lastCreatedLogTime = [NSDate date];

  NSString *sid = _sut.sessionId;
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testStartSessionOnStart {

  // If
  id analyticsMock = OCMClassMock([MSAnalytics class]);
  OCMStub([analyticsMock isAvailable]).andReturn(YES);
  OCMStub([analyticsMock sharedInstance]).andReturn(analyticsMock);
  MSSessionTracker *sut = [[MSSessionTracker alloc] init];
  [sut setSessionTimeout:kMSTestSessionTimeout];
  id<MSSessionTrackerDelegate> delegateMock = OCMProtocolMock(@protocol(MSSessionTrackerDelegate));
  sut.delegate = delegateMock;

  // When
  [sut start];

  // Then
  OCMVerify([delegateMock sessionTracker:sut
                              processLog:[OCMArg isKindOfClass:[MSStartSessionLog class]]
                            withPriority:MSPriorityDefault]);
}

- (void)testStartSessionOnAppForegrounded {

  // If
  id analyticsMock = OCMClassMock([MSAnalytics class]);
  OCMStub([analyticsMock isAvailable]).andReturn(YES);
  OCMStub([analyticsMock sharedInstance]).andReturn(analyticsMock);
  MSSessionTracker *sut = [[MSSessionTracker alloc] init];
  [sut setSessionTimeout:0];
  id<MSSessionTrackerDelegate> delegateMock = OCMProtocolMock(@protocol(MSSessionTrackerDelegate));
  [sut start];

  // When
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];
  [NSThread sleepForTimeInterval:0.1];
  sut.delegate = delegateMock;
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  // Then
  OCMVerify([delegateMock sessionTracker:sut
                              processLog:[OCMArg isKindOfClass:[MSStartSessionLog class]]
                            withPriority:MSPriorityDefault]);
}

@end
