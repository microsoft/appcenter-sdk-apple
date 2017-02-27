#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#import "MSService.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"

#import "MSPush.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"
#import "MSMockPushDelegate.h"
#import "MSPushLog.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestDeviceToken = @"TestDeviceToken";

@interface MSPushTests : XCTestCase <MSPushDelegate>

@property BOOL willSendEventLogWasCalled;
@property BOOL didSucceedSendingEventLogWasCalled;
@property BOOL didFailSendingEventLogWasCalled;

@end

@interface MSPush ()

- (void)channel:(id)channel willSendLog:(id <MSLog>)log;

- (void)channel:(id <MSChannel>)channel didSucceedSendingLog:(id <MSLog>)log;

- (void)channel:(id <MSChannel>)channel didFailSendingLog:(id <MSLog>)log withError:(NSError *)error;

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@implementation MSPushTests

- (void)tearDown {
  [super tearDown];
  [MSPush resetSharedInstance];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  [[MSPush sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  MSServiceAbstract *service = (MSServiceAbstract *) [MSPush sharedInstance];

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);

  [service setEnabled:NO];
  XCTAssertFalse([service isEnabled]);

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);
}

- (void)testSettingDelegateWorks {

  id <MSPushDelegate> delegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  [MSPush setDelegate:delegateMock];
  XCTAssertNotNil([MSPush sharedInstance].delegate);
  XCTAssertEqual([MSPush sharedInstance].delegate, delegateMock);
}

- (void)testPushDelegateWithoutImplementations {

  // When
  MSMockPushDelegate *delegateMock = OCMPartialMock([MSMockPushDelegate new]);
  [MSPush setDelegate:delegateMock];

  id<MSPushDelegate> delegate = [[MSPush sharedInstance] delegate];

  // Then
  XCTAssertFalse([delegate respondsToSelector:@selector(push:willSendInstallLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(push:didSucceedSendingInstallationLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(push:didFailSendingInstallLog:withError:)]);
}

- (void)testAnalyticsDelegateMethodsAreCalled {

  self.willSendEventLogWasCalled = false;
  self.didSucceedSendingEventLogWasCalled = false;
  self.didFailSendingEventLogWasCalled = false;
  [[MSPush sharedInstance] setDelegate:self];
  MSPushLog *pushLog = [MSPushLog new];
  [[MSPush sharedInstance] channel:nil willSendLog:pushLog];
  [[MSPush sharedInstance] channel:nil didSucceedSendingLog:pushLog];
  [[MSPush sharedInstance] channel:nil didFailSendingLog:pushLog withError:nil];

  XCTAssertTrue(self.willSendEventLogWasCalled);
  XCTAssertTrue(self.didSucceedSendingEventLogWasCalled);
  XCTAssertTrue(self.didFailSendingEventLogWasCalled);
}

- (void)testInitializationPriorityCorrect {

  XCTAssertTrue([[MSPush sharedInstance] initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testSendDeviceTokenMethod {

  XCTAssertFalse([MSPush sharedInstance].deviceTokenHasBeenSent);

  [[MSPush sharedInstance] sendDeviceToken:kMSTestDeviceToken];

  XCTAssertTrue([MSPush sharedInstance].deviceTokenHasBeenSent);
}

#pragma mark - Delegate

-(void)push:(MSPush *)push willSendInstallLog:(MSPushLog *)pushLog {

  self.willSendEventLogWasCalled = true;
}

-(void)push:(MSPush *)push didSucceedSendingInstallationLog:(MSPushLog *)pushLog {

  self.didSucceedSendingEventLogWasCalled = true;
}

-(void)push:(MSPush *)push didFailSendingInstallLog:(MSPushLog *)pushLog withError:(NSError *)error {

  self.didFailSendingEventLogWasCalled = true;
}

@end
