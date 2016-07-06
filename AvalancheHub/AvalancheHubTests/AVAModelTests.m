/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "AVALogContainer.h"
#import "AVAEndSessionLog.h"
#import "AVADeviceLog.h"

@interface AVAModelTests : XCTestCase

@end

@implementation AVAModelTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testLogContainerSerialization {
  
  AVALogContainer* logContainer = [[AVALogContainer alloc] init];
  
  AVAEndSessionLog* log1 = [[AVAEndSessionLog alloc] init];
  log1.sid = [NSUUID UUID];
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  
  
  AVAEndSessionLog* log2 = [[AVAEndSessionLog alloc] init];
  log2.sid = [NSUUID UUID];
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  
  logContainer.logs = (NSArray<AVALog>*)@[log1, log2];
  
  NSString* jsonString = [logContainer serializeLog];
  
  XCTAssertTrue([jsonString length] > 0);
}
@end
