#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#import "MSPush.h"
#import "MSPushLog.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"

typedef void(^WillSendInstallationLogCallback)(MSPush*, MSPushLog*);
typedef void(^DidSucceedSendingEventLogCallback)(MSPush*, MSPushLog*);
typedef void(^DidFailSendingEventLogCallback)(MSPush*, MSPushLog*, NSError*);

@interface MSMockPushDelegate : NSObject <MSPushDelegate>
@end

@implementation MSMockPushDelegate
@end

@interface MSPushDelegateWithImplementations : NSObject <MSPushDelegate>

@property WillSendInstallationLogCallback willSendEventLogCallback;
@property DidSucceedSendingEventLogCallback didSucceedSendingEventLogCallback;
@property DidFailSendingEventLogCallback didFailSendingEventLogCallback;

@end

@implementation MSPushDelegateWithImplementations

#pragma mark - Push Delegate implementations

-(void)push:(MSPush *)push willSendInstallationLog:(MSPushLog *)pushLog {
  self.willSendEventLogCallback(push, pushLog);
}

-(void)push:(MSPush *)push didSucceedSendingInstallationLog:(MSPushLog *)pushLog {
  self.didSucceedSendingEventLogCallback(push, pushLog);
}

-(void)push:(MSPush *)push didFailSendingInstallLog:(MSPushLog *)pushLog withError:(NSError *)error {
  self.didFailSendingEventLogCallback(push, pushLog, error);
}

@end

@interface MSPushDelegatesTests : XCTestCase
@end

@implementation MSPushDelegatesTests

- (void)tearDown {
  [MSPush resetSharedInstance];
  [super tearDown];
}

#pragma mark - Tests

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
  XCTAssertFalse([delegate respondsToSelector:@selector(push:willSendInstallationLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(push:didSucceedSendingInstallationLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(push:didFailSendingInstallLog:withError:)]);
}

- (void)testAnalyticsDelegateMethodsAreCalled {
  MSPushDelegateWithImplementations *pushDelegate = [MSPushDelegateWithImplementations new];
  pushDelegate.willSendEventLogCallback = ^(MSPush *push, MSPushLog *pushLog) {
    XCTAssertNotNil(push);
    XCTAssertNotNil(pushLog);
  };
  pushDelegate.didSucceedSendingEventLogCallback = ^(MSPush *push, MSPushLog *pushLog) {
    XCTAssertNotNil(push);
    XCTAssertNotNil(pushLog);
  };
  pushDelegate.didFailSendingEventLogCallback = ^(MSPush *push, MSPushLog *pushLog, NSError *error) {
    XCTAssertNotNil(push);
    XCTAssertNotNil(pushLog);
    XCTAssertNotNil(error);
  };

  [[MSPush sharedInstance] setDelegate:pushDelegate];

  MSPushLog *pushLog = [MSPushLog new];
  NSError *error = [NSError new];
  [[MSPush sharedInstance] channel:nil willSendLog:pushLog];
  [[MSPush sharedInstance] channel:nil didSucceedSendingLog:pushLog];
  [[MSPush sharedInstance] channel:nil didFailSendingLog:pushLog withError:error];
}

@end
