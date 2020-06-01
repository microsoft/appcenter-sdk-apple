// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextDelegate.h"
#import "MSUserIdContextPrivate.h"
#import "MSUtility.h"

@interface MSUserIdContextTests : XCTestCase

@property(nonatomic) MSUserIdContext *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;

@end

@implementation MSUserIdContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSUserIdContext sharedInstance];
}

- (void)tearDown {
  [MSUserIdContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [super tearDown];
}

#pragma mark - Tests

- (void)testSetUserId {

  // If
  NSString *expectedUserId = @"alice";

  // When
  [[MSUserIdContext sharedInstance] setUserId:expectedUserId];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"UserIdHistory"];
  XCTAssertNotNil(data);
  NSMutableArray *savedData = (NSMutableArray *)[[MSUtility unarchiveKeyedData:data] mutableCopy];
  XCTAssertEqualObjects([savedData[0] userId], expectedUserId);
}

- (void)testClearUserIdHistory {

  // When
  [[MSUserIdContext sharedInstance] setUserId:@"UserId1"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId2"];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"UserIdHistory"];
  XCTAssertNotNil(data);
  NSMutableArray *savedData = (NSMutableArray *)[[MSUtility unarchiveKeyedData:data] mutableCopy];

  XCTAssertEqual([savedData count], 2);

  // When
  [[MSUserIdContext sharedInstance] clearUserIdHistory];

  // Then
  data = [self.settingsMock objectForKey:@"UserIdHistory"];
  XCTAssertNotNil(data);

  // Should keep the current userId.
  savedData = (NSMutableArray *)[[MSUtility unarchiveKeyedData:data] mutableCopy];
  XCTAssertEqual([savedData count], 1);
}

- (void)testUserId {

  // If
  NSString *expectedUserId = @"UserId";

  // When
  [[MSUserIdContext sharedInstance] setUserId:expectedUserId];

  // Then
  XCTAssertEqualObjects(expectedUserId, [[MSUserIdContext sharedInstance] userId]);
}

- (void)testUserIdAt {

  // If
  __block NSDate *date;
  id dateMock = OCMClassMock([NSDate class]);

  // When
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    [invocation setReturnValue:&date];
  });
  [[MSUserIdContext sharedInstance] setUserId:@"UserId1"];
  [dateMock stopMocking];

  [MSUserIdContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:1000];
    [invocation setReturnValue:&date];
  });
  [[MSUserIdContext sharedInstance] setUserId:@"UserId2"];
  [dateMock stopMocking];

  [MSUserIdContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:2000];
    [invocation setReturnValue:&date];
  });
  [[MSUserIdContext sharedInstance] setUserId:@"UserId3"];
  [dateMock stopMocking];

  [MSUserIdContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:3000];
    [invocation setReturnValue:&date];
  });
  [[MSUserIdContext sharedInstance] setUserId:@"UserId4"];
  [dateMock stopMocking];

  [MSUserIdContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:4000];
    [invocation setReturnValue:&date];
  });
  [[MSUserIdContext sharedInstance] setUserId:@"UserId5"];
  [dateMock stopMocking];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:0]]);
  XCTAssertEqualObjects(@"UserId3", [[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:2500]]);
  XCTAssertEqualObjects(@"UserId5", [[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:5000]]);
}

- (void)testPrefixedUserIdFromUserId {

  // Then
  XCTAssertEqualObjects([MSUserIdContext prefixedUserIdFromUserId:@"c:alice"], @"c:alice");
  XCTAssertEqualObjects([MSUserIdContext prefixedUserIdFromUserId:@"alice"], @"c:alice");
  XCTAssertEqualObjects([MSUserIdContext prefixedUserIdFromUserId:@":"], @":");
  XCTAssertNil([MSUserIdContext prefixedUserIdFromUserId:nil]);
}

- (void)testDelegateCalledOnUserIdChanged {

  // If
  XCTAssertNil([self.sut currentUserIdInfo].userId);
  NSString *expectedUserId = @"Robert";
  id delegateMock = OCMProtocolMock(@protocol(MSUserIdContextDelegate));
  [self.sut addDelegate:delegateMock];
  OCMExpect([delegateMock userIdContext:self.sut didUpdateUserId:expectedUserId]);

  // When
  [[MSUserIdContext sharedInstance] setUserId:expectedUserId];

  // Then
  XCTAssertEqual([self.sut userId], expectedUserId);
  OCMVerify([delegateMock userIdContext:self.sut didUpdateUserId:expectedUserId]);
}

- (void)testDelegateCalledOnUserIdChangedToNil {
  
  // If
  NSString *userId = @"Robert";
  [[MSUserIdContext sharedInstance] setUserId:userId];
  id delegateMock = OCMProtocolMock(@protocol(MSUserIdContextDelegate));
  [self.sut addDelegate:delegateMock];
  OCMExpect([delegateMock userIdContext:self.sut didUpdateUserId:nil]);
  
  // When
  [[MSUserIdContext sharedInstance] setUserId:nil];
  
  // Then
  XCTAssertEqual([self.sut userId], nil);
  OCMVerify([delegateMock userIdContext:self.sut didUpdateUserId:nil]);
}

- (void)testDelegateNotCalledOnUserIdSame {

  // If
  NSString *expectedUserId = @"Patrick";
  [[MSUserIdContext sharedInstance] setUserId:expectedUserId];
  id delegateMock = OCMProtocolMock(@protocol(MSUserIdContextDelegate));
  [self.sut addDelegate:delegateMock];
  OCMReject([delegateMock userIdContext:self.sut didUpdateUserId:expectedUserId]);

  // When
  [[MSUserIdContext sharedInstance] setUserId:expectedUserId];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testRemoveDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSUserIdContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut removeDelegate:delegateMock];

  // Then
  XCTAssertEqual([[self.sut delegates] count], 0);
}

@end
