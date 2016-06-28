//
//  AvalancheHubTests.m
//  AvalancheHubTests
//
//  Created by Christoph Wendt on 6/28/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface AvalancheHubTests : XCTestCase

@end

@implementation AvalancheHubTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
  
}

- (void)testOCHamcrest {
  NSString* aString = @"Test String";
  NSString* bString = @"Test String";
  assertThat(aString, equalTo(bString));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
