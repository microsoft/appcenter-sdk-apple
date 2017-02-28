#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#import "MSService.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"

#import "MSPush.h"
#import "MSPushLog.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestDeviceToken = @"TestDeviceToken";

@interface MSPushTests : XCTestCase
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

- (void)testInitializationPriorityCorrect {

  XCTAssertTrue([[MSPush sharedInstance] initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testSendDeviceTokenMethod {

  XCTAssertFalse([MSPush sharedInstance].deviceTokenHasBeenSent);

  [[MSPush sharedInstance] sendDeviceToken:kMSTestDeviceToken];

  XCTAssertTrue([MSPush sharedInstance].deviceTokenHasBeenSent);
}

@end
