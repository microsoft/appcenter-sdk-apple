// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAlertController.h"
#import "MSACTestFrameworks.h"

static NSTimeInterval const kMSACTestTimeout = 1.0;

@interface MSACAlertControllerTests : XCTestCase

@end

@interface MSACAlertController (Testing)

+ (void)makeKeyAndVisible;

+ (void)presentNextAlertAnimated:(BOOL)animated;

@end

@implementation MSACAlertControllerTests

- (void)setUp {

  // Refresh static variables
  [MSACAlertController initialize];
}

- (void)testAlertAddDefaultAction {

  // If
  MSACAlertController *controller = [MSACAlertController new];

  // When
  [controller addDefaultActionWithTitle:@"testAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleDefault);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"testAction");
}

- (void)testAlertAddCancelAction {

  // If
  MSACAlertController *controller = [MSACAlertController new];

  // When
  [controller addCancelActionWithTitle:@"cancelAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleCancel);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"cancelAction");
}

- (void)testAlertAddDestructiveAction {

  // If
  MSACAlertController *controller = [MSACAlertController new];

  // When
  [controller addDestructiveActionWithTitle:@"destructiveAction" handler:nil];

  // Then
  XCTAssertEqual([controller actions].count, 1);
  XCTAssertEqual([[controller actions] firstObject].style, UIAlertActionStyleDestructive);
  XCTAssertEqualObjects([[controller actions] firstObject].title, @"destructiveAction");
}

- (void)testAlertAddPreferredAction {

  // If
  id controller = OCMPartialMock([MSACAlertController new]);

  // When
  [controller addPreferredActionWithTitle:@"preferredAction" handler:nil];

  // Then
  OCMVerify([controller setPreferredAction:OCMOCK_ANY]);
  XCTAssertEqual([controller actions].count, 1);

  [controller stopMocking];
}

- (void)testAlertShow {

  // If
  MSACAlertController *controller = [MSACAlertController new];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Window is key and visible"];
  id alertClassMock = OCMClassMock([MSACAlertController class]);
  OCMStub(ClassMethod([alertClassMock makeKeyAndVisible])).andDo(^(__unused NSInvocation *invoke) {
    [expectation fulfill];
  });

  // When
  [controller show];

  // Then
  [self waitForExpectationsWithTimeout:kMSACTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  [alertClassMock stopMocking];
}

- (void)testAlertReplace {

  // If
  id controller = OCMPartialMock([MSACAlertController new]);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Window is key and visible"];
  id alertClassMock = OCMClassMock([MSACAlertController class]);
  OCMStub(ClassMethod([alertClassMock makeKeyAndVisible])).andDo(^(__unused NSInvocation *invoke) {
    [expectation fulfill];
  });

  // When
  [controller replaceAlert:nil];

  // Then
  [self waitForExpectationsWithTimeout:kMSACTestTimeout
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
  MSACAlertController *controller = [MSACAlertController new];
  id alertClassMock = OCMClassMock([MSACAlertController class]);
  OCMReject([alertClassMock makeKeyAndVisible]);

  // When
  [controller viewDidDisappear:NO];

  // Then
  OCMVerify([alertClassMock presentNextAlertAnimated:NO]);

  [alertClassMock stopMocking];
}

@end
