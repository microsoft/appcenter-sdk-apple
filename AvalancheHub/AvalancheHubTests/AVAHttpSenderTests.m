//
//  AVAHttpSenderTests.m
//  AvalancheHub
//
//  Created by Mehrdad Mozafari on 6/30/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AVAHttpSender.h"
#import "AVAInSessionLog.h"
#import "AVADeviceLog.h"
#import "AVALogContainer.h"
#import "AvalancheHub+Internal.h"


static NSString* const kBaseUrl = @"https://test.com";

@interface AVAHttpSenderTests : XCTestCase

@property(nonatomic, strong) AVAHttpSender *sut;

@end



@implementation AVAHttpSenderTests

- (void)setUp {
  [super setUp];
  // System under test
  _sut = [[AVAHttpSender alloc] initWithBaseUrl:kBaseUrl];
  
}

- (void)tearDown {
  [super tearDown];
}

- (void)testSendBatchLogs {
  
  AVALogContainer* logContainer = [[AVALogContainer alloc] init];

  AVAInSessionLog* log1 = [[AVAInSessionLog alloc] init];
  log1.sid = @"sessionId1";
  
  AVADeviceLog* log2 = [[AVADeviceLog alloc] init];
  log2.sdkVersion = @"1.0.0";
  
  logContainer.logs = (NSArray<AVALog>*)@[log1, log2];
  
  [_sut sendLogsAsync:logContainer callbackQueue:dispatch_get_main_queue() priority:AVASendPriorityDefault completionHandler:^(NSError *error, NSUInteger statusCode, NSString *batchId) {
    AVALogVerbose(@"%@", [error localizedDescription]);
  }];
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}



@end
