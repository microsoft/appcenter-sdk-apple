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
#import "AVAAvalanche.h"
#import "AVAAvalanchePrivate.h"

#import "OHHTTPStubs.h"
#import "OCMock.h"


static AVAAvalanche* mockAvalancheHub = nil;
static NSTimeInterval const kTestTimeout = 5.0;
static NSString* const kBaseUrl = @"https://test.com";


// Create a category for Avalanche class
@implementation AVAAvalanche (UnitTests)

+ (id)sharedInstance {
  return mockAvalancheHub;
}

@end


@interface AVAHttpSenderTests : XCTestCase

@property(nonatomic, strong) AVAHttpSender *sut;

@end

@implementation AVAHttpSenderTests

- (void)setUp {
  [super setUp];
  
  // sut: System under test
  _sut = [[AVAHttpSender alloc] initWithBaseUrl:kBaseUrl];
}

- (void)tearDown {
  [super tearDown];
  
  [OHHTTPStubs removeAllStubs];
}

- (void)stubNSURLSession {
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    NSData* stubData = [@"Avalanche Response" dataUsingEncoding:NSUTF8StringEncoding];
    return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:nil];
  }].name = @"httpStub_200";
  
  [OHHTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<OHHTTPStubsDescriptor>  _Nonnull stub, OHHTTPStubsResponse * _Nonnull responseStub) {
    NSLog(@"%@ stubbed by %@.", request.URL, stub.name);
  }];
}

- (void)mockAvalancheHub {
  id mockHub = OCMClassMock([AVAAvalanche class]);
  OCMStub([mockHub appId]).andReturn(@"mockAppID");
  OCMStub([mockHub UUID]).andReturn([[NSUUID UUID] UUIDString]);
  OCMStub([mockHub apiVersion]).andReturn(@"2016-09-01");
  
  mockAvalancheHub = mockHub;
}

- (void)testSendBatchLogs {
  [self mockAvalancheHub];
  [self stubNSURLSession];

  AVALogContainer* logContainer = [[AVALogContainer alloc] init];

  AVAInSessionLog* log1 = [[AVAInSessionLog alloc] init];
  log1.sid = @"sessionId1";
  
  AVADeviceLog* log2 = [[AVADeviceLog alloc] init];
  log2.sdkVersion = @"1.0.0";
  
  logContainer.logs = (NSArray<AVALog>*)@[log1, log2];
  
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [_sut sendLogsAsync:logContainer callbackQueue:dispatch_get_main_queue() priority:AVASendPriorityDefault completionHandler:^(NSError *error, NSUInteger statusCode, NSString *batchId) {
    AVALogVerbose(@"%@", [error localizedDescription]);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:kTestTimeout handler:^(NSError * _Nullable error) {
    if(error)
    {
      XCTFail(@"Expectation Failed with error: %@", error);
    }
  }];
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}

@end
