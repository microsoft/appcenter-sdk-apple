#import "OCMock.h"
#import <XCTest/XCTest.h>

#import "AVAChannelDefault.h"
#import "AVAMockLog.h"
#import "AVASessionTracker.h"
#import "AvalancheHub+Internal.h"

NSTimeInterval const kAVATestSessionTimeout = 2.0;

@interface AVASessionTrackerTests : XCTestCase

@property(nonatomic) AVASessionTracker *sut;

@end

@implementation AVASessionTrackerTests

- (void)setUp {
  [super setUp];

  id channelMock = OCMClassMock([AVAChannelDefault class]);

  NSDate *date = [NSDate date];
  OCMStub([channelMock lastQueuedLogTime]).andReturn(date);

  _sut = [[AVASessionTracker alloc] initWithChannel:channelMock];
  [_sut setSessionTimeout:kAVATestSessionTimeout];
  [_sut start];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}

- (void)testSession {

  NSString *expectedSid;

  // Verify the creation of sid and device log
  {
    expectedSid = [_sut getSessionId];

    XCTAssertNotNil(expectedSid);
  }

  // Verify reuse of the same session id on next get
  {
    NSString *sid = [_sut getSessionId];

    XCTAssertEqual(expectedSid, sid);
  }
}

// Apps is in foreground for longer than the timeout time, still same session
- (void)testLongForegroundSession {
  NSString *expectedSid = [_sut getSessionId];

  // Wait for longer than timeout in foreground
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 1];

  NSString *sid = [_sut getSessionId];
  XCTAssertEqual(expectedSid, sid);
}

- (void)testShortBackgroundSession {
  NSString *expectedSid = [_sut getSessionId];

  // Enter background
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:self];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout - 1];

  // Enter foreground
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:self];

  NSString *sid = [_sut getSessionId];

  XCTAssertEqual(expectedSid, sid);
}

- (void)testLongBackgroundSession {
  NSString *expectedSid = [_sut getSessionId];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:self];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 1];

  // Enter foreground
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:self];

  NSString *sid = [_sut getSessionId];
  XCTAssertNotEqual(expectedSid, sid);
}

- (void)testLongBackgroundSessionWithSessionTrackingStopped {

  // Stop session tracking
  [_sut stop];

  NSString *expectedSid = [_sut getSessionId];

  XCTAssertNotNil(expectedSid);

  // Enter background
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:self];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 1];

  // Enter foreground
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:self];

  NSString *sid = [_sut getSessionId];
  XCTAssertEqual(expectedSid, sid);
}

@end
