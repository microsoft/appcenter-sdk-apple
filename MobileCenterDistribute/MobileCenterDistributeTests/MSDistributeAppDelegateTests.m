#import "MSTestFrameworks.h"
#import "MSDistributePrivate.h"
#import "MSDistributeAppDelegate.h"

@interface MSDistributeAppDelegateTests : XCTestCase

@end

@implementation MSDistributeAppDelegateTests

- (void)testOpenURLIsCalled {

  // If.
  MSDistributeAppDelegate *appDelegate = [[MSDistributeAppDelegate alloc] init];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  NSURL *url = [[NSURL alloc] init];

  // When.
  [appDelegate application: [UIApplication sharedApplication] openURL: url options:@{} returnedValue:YES];

  // Then.
  OCMVerify([distributeMock openURL:url]);

  // When.
  [appDelegate application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:@"" returnedValue:YES];

  // Then.
  OCMVerify([distributeMock openURL:url]);
}


@end
