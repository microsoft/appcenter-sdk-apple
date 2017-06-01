#import "MSAnalytics.h"
#import "MSConstants+Internal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerUtil.h"
#import "MSStartSessionLog.h"
#import "MSTestFrameworks.h"

static NSTimeInterval const kMSTestSessionTimeout = 1.5;

@interface MSSessionTrackerTests : XCTestCase

@property(nonatomic) MSSessionTracker *sut;

@end

@implementation MSSessionTrackerTests

- (void)setUp {
  [super setUp];

  self.sut = [[MSSessionTracker alloc] init];
  [self.sut setSessionTimeout:kMSTestSessionTimeout];
  [self.sut start];

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
    expectedSid = self.sut.sessionId;

    XCTAssertNotNil(expectedSid);
  }

  // Verify reuse of the same session id on next get
  {
    NSString *sid = self.sut.sessionId;

    XCTAssertEqual(expectedSid, sid);
  }
}

// Apps is in foreground for longer than the timeout time, still same session
- (void)testLongForegroundSession {
  NSString *expectedSid = self.sut.sessionId;
  // mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Wait for longer than timeout in foreground
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  NSString *sid = self.sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testShortBackgroundSession {
  NSString *expectedSid = self.sut.sessionId;
  // mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout - 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  NSString *sid = self.sut.sessionId;

  XCTAssertEqual(expectedSid, sid);
}

- (void)testLongBackgroundSession {
  NSString *expectedSid = self.sut.sessionId;
  // mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  NSString *sid = self.sut.sessionId;
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testLongBackgroundSessionWithSessionTrackingStopped {

  // Stop session tracking
  [self.sut stop];

  NSString *expectedSid = self.sut.sessionId;
  // mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_IPHONE
      postNotificationName:UIApplicationWillEnterForegroundNotification
#else
      postNotificationName:NSApplicationWillBecomeActiveNotification
#endif
                    object:self];

  NSString *sid = self.sut.sessionId;
  XCTAssertEqual(expectedSid, sid);
}

- (void)testTooLongInBackground {

  // If
  NSString *expectedSid = self.sut.sessionId;

  // Then
  XCTAssertNotNil(expectedSid);

  // When
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];
  [NSThread sleepForTimeInterval:1];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // mock a log creation while app is in background
  self.sut.lastCreatedLogTime = [NSDate date];
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];
  NSString *sid = self.sut.sessionId;

  // Then
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
  OCMVerify([delegateMock sessionTracker:sut processLog:[OCMArg isKindOfClass:[MSStartSessionLog class]]]);
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
  OCMVerify([delegateMock sessionTracker:sut processLog:[OCMArg isKindOfClass:[MSStartSessionLog class]]]);
}

- (void)testOnProcessingLog {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];

  // Then
  XCTAssertNil(log.sid);
  XCTAssertNil(log.toffset);

  // When
  [self.sut onEnqueuingLog:log withInternalId:nil];

  // Then
  XCTAssertNil(log.toffset);
  XCTAssertEqual(log.sid, self.sut.sessionId);

  // When
  log.toffset = 0;
  [self.sut onEnqueuingLog:log withInternalId:nil];

  // Then
  XCTAssertEqual(0, log.toffset.integerValue);
  XCTAssertEqual(log.sid, [self.sut.pastSessions firstObject].sessionId);

  // When
  log.toffset = [NSNumber numberWithUnsignedLongLong:UINT64_MAX];
  [self.sut onEnqueuingLog:log withInternalId:nil];

  // Then
  XCTAssertEqual(UINT64_MAX, log.toffset.unsignedLongLongValue);
  XCTAssertEqual(log.sid, [self.sut.pastSessions lastObject].sessionId);
};

@end
