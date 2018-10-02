#import "MSAnalytics.h"
#import "MSLogWithProperties.h"
#import "MSSessionContextPrivate.h"
#import "MSSessionTrackerPrivate.h"
#import "MSSessionTrackerUtil.h"
#import "MSStartServiceLog.h"
#import "MSStartSessionLog.h"
#import "MSTestFrameworks.h"

static NSTimeInterval const kMSTestSessionTimeout = 1.5;

@interface MSSessionTrackerTests : XCTestCase

@property(nonatomic) MSSessionTracker *sut;
@property(nonatomic) id context;

@end

@implementation MSSessionTrackerTests

- (void)setUp {
  [super setUp];

  self.sut = [[MSSessionTracker alloc] init];
  [self.sut setSessionTimeout:kMSTestSessionTimeout];
  self.sut.context = [MSSessionContext new];
  [self.sut start];
}

- (void)tearDown {
  [super tearDown];
  [MSSessionContext resetSharedInstance];

  // This is required to remove observers in dealloc.
  self.sut = nil;
}

- (void)testSession {

  // When
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(expectedSid);

  // When
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertEqual(expectedSid, sid);
}

// Apps is in foreground for longer than the timeout time, still same session
- (void)testLongForegroundSession {

  // If
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(expectedSid);

  // When

  // Mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Wait for longer than timeout in foreground
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  // Get a session
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertEqual(expectedSid, sid);
}

- (void)testShortBackgroundSession {

  // If
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(expectedSid);

  // When

  // Mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout - 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  // Get a session
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertEqual(expectedSid, sid);
}

- (void)testLongBackgroundSession {

  // If
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(expectedSid);

  // When

  // Mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  // Enter foreground
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];

  // Get a session
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testLongBackgroundSessionWithSessionTrackingStopped {

  // If
  [self.sut stop];

  // When

  // Mock a log creation
  self.sut.lastCreatedLogTime = [NSDate date];

  // Get a session
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNil(expectedSid);

  // When

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_OSX
      postNotificationName:NSApplicationWillBecomeActiveNotification
#else
      postNotificationName:UIApplicationWillEnterForegroundNotification
#endif
                    object:self];

  // Get a session
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertNil(sid);
}

- (void)testTooLongInBackground {

  // If
  [self.sut renewSessionId];
  NSString *expectedSid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(expectedSid);

  // When
  [MSSessionTrackerUtil simulateWillEnterForegroundNotification];
  [NSThread sleepForTimeInterval:1];

  // Enter background
  [MSSessionTrackerUtil simulateDidEnterBackgroundNotification];

  // Mock a log creation while app is in background
  self.sut.lastCreatedLogTime = [NSDate date];

  // Wait for longer than timeout in background
  [NSThread sleepForTimeInterval:kMSTestSessionTimeout + 1];

  // Get a session
  [self.sut renewSessionId];
  NSString *sid = [self.sut.context sessionId];

  // Then
  XCTAssertNotNil(sid);
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testStartSessionOnStart {

  // Clean up session context and stop session tracker which is initialized in setUp.
  [MSSessionContext resetSharedInstance];
  [self.sut stop];

  // If
  id analyticsMock = OCMClassMock([MSAnalytics class]);
  OCMStub([analyticsMock isAvailable]).andReturn(YES);
  OCMStub([analyticsMock sharedInstance]).andReturn(analyticsMock);
  [self.sut setSessionTimeout:kMSTestSessionTimeout];
  id<MSSessionTrackerDelegate> delegateMock = OCMProtocolMock(@protocol(MSSessionTrackerDelegate));
  self.sut.delegate = delegateMock;

  // When
  [self.sut start];

  // Then
  OCMVerify([delegateMock sessionTracker:self.sut processLog:[OCMArg isKindOfClass:[MSStartSessionLog class]]]);
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

- (void)testDidEnqueueLog {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];

  // Then
  XCTAssertNil(log.sid);
  XCTAssertNil(log.timestamp);

  // When
  [self.sut channel:nil prepareLog:log];

  // Then
  XCTAssertNil(log.timestamp);
  XCTAssertEqual(log.sid, [self.sut.context sessionId]);
}

- (void)testNoStartSessionWithStartSessionLog {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];

  // Then
  XCTAssertNil(log.sid);
  XCTAssertNil(log.timestamp);

  // When
  [self.sut channel:nil prepareLog:log];

  // Then
  XCTAssertNil(log.timestamp);
  XCTAssertEqual(log.sid, [self.sut.context sessionId]);

  // If
  MSStartSessionLog *sessionLog = [MSStartSessionLog new];

  // Then
  XCTAssertNil(sessionLog.sid);
  XCTAssertNil(sessionLog.timestamp);

  // When
  [self.sut channel:nil prepareLog:sessionLog];

  // Then
  XCTAssertNil(sessionLog.timestamp);
  XCTAssertNil(sessionLog.sid);

  // If
  MSStartServiceLog *serviceLog = [MSStartServiceLog new];

  // Then
  XCTAssertNil(serviceLog.sid);
  XCTAssertNil(serviceLog.timestamp);

  // When
  [self.sut channel:nil prepareLog:serviceLog];

  // Then
  XCTAssertNil(serviceLog.timestamp);
  XCTAssertNil(serviceLog.sid);
}

@end
