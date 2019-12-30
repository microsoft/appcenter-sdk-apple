// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTestFrameworks.h"
#import "MSAlertController.h"

static NSTimeInterval const kMSTestTimeout = 1.0;

@interface MSAlertControllerTests : XCTestCase

@end

@interface MSAlertController (Testing)

+ (void)makeKeyAndVisible;

@end

@implementation MSAlertControllerTests

- (void)testMSAlertAddAction {
    MSAlertController *controller = [MSAlertController new];

    [controller addDefaultActionWithTitle:@"testAction" handler:nil];

    XCTAssertTrue([controller actions].count == 1);
    XCTAssertTrue([[[controller actions] firstObject].title isEqual:@"testAction"]);
}

- (void)testMSAlertShow {

    // If
    id controller = [MSAlertController new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Window is key and visible"];
    id alertClassMock = OCMClassMock([MSAlertController class]);
    OCMStub(ClassMethod([alertClassMock makeKeyAndVisible])).andDo(^(NSInvocation *invoke) {
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

- (void)testMSAlertReplaceNil {

    // If
    id controller = OCMPartialMock([MSAlertController new]);

    OCMStub([controller showAnimated:OCMOCK_ANY]).andDo(nil);

    // When
    [controller replaceAlert:nil];

    // Then
    OCMVerify([controller showAnimated:OCMOCK_ANY]);

    [controller stopMocking];
}

@end
