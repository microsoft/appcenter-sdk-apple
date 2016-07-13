#import "OCMock.h"
#import <XCTest/XCTest.h>

#import "AVAChannelDefault.h"
#import "AVAChannelSessionDecorator.h"
#import "AVAMockLog.h"
#import "AvalancheHub+Internal.h"

NSTimeInterval const kAVATestSessionTimeout = 5.0;

@interface AVAChannelSessionDecoratorTests : XCTestCase

@property(nonatomic) AVAChannelSessionDecorator *sut;
@end

@implementation AVAChannelSessionDecoratorTests

- (void)setUp {
  [super setUp];

  id channel = OCMClassMock([AVAChannelDefault class]);

  _sut = [[AVAChannelSessionDecorator alloc] initWithChannel:channel];
  [_sut setSessionTimeout:kAVATestSessionTimeout];
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
  AVADeviceLog *expectedDevice;
  {
    AVAMockLog *mockLog = [[AVAMockLog alloc] init];
    [_sut enqueueItem:mockLog];

    XCTAssertNotNil(mockLog.sid);
    XCTAssertNotNil(mockLog.device);

    expectedSid = mockLog.sid;
    expectedDevice = mockLog.device;
  }

  // Verify reuse of the same session for next log
  {
    AVAMockLog *mockLog = [[AVAMockLog alloc] init];
    [_sut enqueueItem:mockLog];

    XCTAssertEqual(expectedSid, mockLog.sid);
    XCTAssertTrue([expectedDevice isEqual:mockLog.device]);
  }

  // Apps is in foreground for longer than the timeout time, still same session
  // ID
  {
    // Wait for longer than timeout in foreground
    [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 2];

    AVAMockLog *mockLog = [[AVAMockLog alloc] init];
    [_sut enqueueItem:mockLog];

    XCTAssertEqual(expectedSid, mockLog.sid);
  }
}

- (void)testLongForegroundSession {
  NSString *expectedSid;

  AVAMockLog *mockLog = [[AVAMockLog alloc] init];
  [_sut enqueueItem:mockLog];

  XCTAssertNotNil(mockLog.sid);

  // Save the sid
  expectedSid = mockLog.sid;

  // Wait for longer than timeout in foreground
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 2];

  [_sut enqueueItem:mockLog];

  XCTAssertEqual(expectedSid, mockLog.sid);
}

- (void)testShortBackgroundSession {
  NSString *expectedSid;

  AVAMockLog *mockLog = [[AVAMockLog alloc] init];
  [_sut enqueueItem:mockLog];

  XCTAssertNotNil(mockLog.sid);

  // Save the sid
  expectedSid = mockLog.sid;

  // Enter background
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:self];

  // Wait for shorter than the timeout time in background
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout - 2];

  // Enter foreground
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:self];

  [_sut enqueueItem:mockLog];

  XCTAssertEqual(expectedSid, mockLog.sid);
}

- (void)testLongBackgroundSession {
  NSString *expectedSid;

  AVAMockLog *mockLog = [[AVAMockLog alloc] init];
  [_sut enqueueItem:mockLog];

  XCTAssertNotNil(mockLog.sid);

  // Save the sid
  expectedSid = mockLog.sid;

  // Enter background
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:self];

  // Wait for longer than the timeout time in background
  [NSThread sleepForTimeInterval:kAVATestSessionTimeout + 2];

  // Enter foreground
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:self];

  [_sut enqueueItem:mockLog];

  XCTAssertNotEqual(expectedSid, mockLog.sid);
}

- (BOOL)areDevicesEqual:(AVADeviceLog *)device1 device:(AVADeviceLog *)device2 {

  if (!device1 && device2)
    return YES;

  return [device1.sdkVersion isEqualToString:device2.sdkVersion] &&
         [device1.model isEqualToString:device2.model] &&
         [device1.oemName isEqualToString:device2.oemName] &&
         [device1.osName isEqualToString:device2.osName] &&
         [device1.osVersion isEqualToString:device2.osVersion] &&
         [device1.osApiLevel isEqualToNumber:device2.osApiLevel] &&
         [device1.locale isEqualToString:device2.locale] &&
         [device1.timeZoneOffset isEqualToNumber:device2.timeZoneOffset] &&
         [device1.screenSize isEqualToString:device2.screenSize] &&
         [device1.appVersion isEqualToString:device2.appVersion] &&
         [device1.carrierName isEqualToString:device2.carrierName] &&
         [device1.carrierCountry isEqualToString:device2.carrierCountry] &&
         [device1.appBuild isEqualToString:device2.appBuild] &&
         [device1.appNamespace isEqualToString:device2.appNamespace];
}

@end
