#import "MSDistributeAppDelegate.h"
#import "MSDistributePrivate.h"
#import "MSTestFrameworks.h"

@interface MSDistributeAppDelegateTests : XCTestCase

@end

@implementation MSDistributeAppDelegateTests

- (void)testOpenURLIsCalled {

  // If
  MSDistributeAppDelegate *appDelegate = [[MSDistributeAppDelegate alloc] init];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  __block int count = 0;
  OCMStub([distributeMock openURL:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    count++;
  });
  NSURL *url = [[NSURL alloc] init];

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url options:@{} returnedValue:YES];

  // Then
  OCMVerify([distributeMock openURL:url]);

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:@"" returnedValue:YES];

  // Then
  OCMVerify([distributeMock openURL:url]);
  XCTAssertEqual(count, 2);
}

@end
