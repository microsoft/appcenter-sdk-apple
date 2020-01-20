// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAlertController.h"
#import "MSTestFrameworks.h"

static NSTimeInterval const kMSTestTimeout = 1.0;

@interface MSAlertControllerTests : XCTestCase

@end

@interface MSAlertController (Testing)

+ (void)makeKeyAndVisible;

+ (void)presentNextAlertAnimated:(BOOL)animated;

@end

@implementation MSAlertControllerTests

- (void)setUp {

  // Refresh static variables
  [MSAlertController initialize];
}

- (void)testAlertAddDefaultAction {

  // If
  MSAlertController *controller = [MSAlertController new];

  // When
  [controller addDefaultActionWithTitle:@"testAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleDefault);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"testAction");
}

- (void)testAlertAddCancelAction {

  // If
  MSAlertController *controller = [MSAlertController new];

  // When
  [controller addCancelActionWithTitle:@"cancelAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleCancel);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"cancelAction");
}

- (void)testAlertAddDestructiveAction {

  // If
  MSAlertController *controller = [MSAlertController new];

  // When
  [controller addDestructiveActionWithTitle:@"destructiveAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleDestructive);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"destructiveAction");
}

- (void)testAlertAddPreferredAction {

  // If
  id controller = OCMPartialMock([MSAlertController new]);

  // When
  [controller addPreferredActionWithTitle:@"preferredAction" handler:nil];

  // Then
  OCMVerify([controller setPreferredAction:OCMOCK_ANY]);
  XCTAssertEqual([controller actions].count, 1);

  [controller stopMocking];
}

- (void)testAlertShow {

  // If
  MSAlertController *controller = [MSAlertController new];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Window is key and visible"];
  id alertClassMock = OCMClassMock([MSAlertController class]);
  OCMStub(ClassMethod([alertClassMock makeKeyAndVisible])).andDo(^(__unused NSInvocation *invoke) {
    [expectation fulfill];
  });

  // When
  [controller show];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  [alertClassMock stopMocking];
}

- (void)testAlertReplace {

  // If
  id controller = OCMPartialMock([MSAlertController new]);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Window is key and visible"];
  id alertClassMock = OCMClassMock([MSAlertController class]);
  OCMStub(ClassMethod([alertClassMock makeKeyAndVisible])).andDo(^(__unused NSInvocation *invoke) {
    [expectation fulfill];
  });

  // When
  [controller replaceAlert:nil];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  ;

  [controller stopMocking];
}

- (void)testAlertDisappear {

  // If
  MSAlertController *controller = [MSAlertController new];
  id alertClassMock = OCMClassMock([MSAlertController class]);
  OCMReject([alertClassMock makeKeyAndVisible]);

  // When
  [controller viewDidDisappear:NO];

  // Then
  OCMVerify([alertClassMock presentNextAlertAnimated:NO]);

  [alertClassMock stopMocking];
}

@end
