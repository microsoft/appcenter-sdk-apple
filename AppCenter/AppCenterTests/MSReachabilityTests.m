// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MS_Reachability.h"
#import "MSTestFrameworks.h"

@interface MSReachabilityTests : XCTestCase
@end

@implementation MSReachabilityTests

- (void)testRaceConditionOnDealloc {
  
  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Reachability deallocated."];

  // When
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MS_Reachability *reachability = [MS_Reachability reachabilityForInternetConnection];
    reachability = nil;
  });
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    // Arbitrary wait for reachability dealocation so if a EXC_BAD_ACCESS happens it has a chance to happen in this test.
    [NSThread sleepForTimeInterval:0.1];
    [expectation fulfill];
  });
  
  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

@end
