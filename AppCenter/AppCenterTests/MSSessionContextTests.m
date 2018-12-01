#import <Foundation/Foundation.h>

#import "MSMockUserDefaults.h"
#import "MSSessionContextPrivate.h"
#import "MSTestFrameworks.h"

@interface MSSessionContextTests : XCTestCase

@property(nonatomic) MSSessionContext *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;

@end

@implementation MSSessionContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSSessionContext sharedInstance];
}

- (void)tearDown {
  [MSSessionContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [super tearDown];
}

#pragma mark - Tests

- (void)testSetSessionId {

  // If
  NSString *expectedSessionId = @"Session";

  // When
  [[MSSessionContext sharedInstance] setSessionId:expectedSessionId];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertEqualObjects([[NSKeyedUnarchiver unarchiveObjectWithData:data][0] sessionId], expectedSessionId);
}

- (void)testClearSessionHistory {

  // When
  [[MSSessionContext sharedInstance] setSessionId:@"Session1"];
  [MSSessionContext resetSharedInstance];
  [[MSSessionContext sharedInstance] setSessionId:@"Session2"];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertTrue([[NSKeyedUnarchiver unarchiveObjectWithData:data] count] == 2);

  // When
  [[MSSessionContext sharedInstance] clearSessionHistoryAndKeepCurrentSession:NO];

  // Then
  data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);

  // Should keep the current session.
  XCTAssertTrue([[NSKeyedUnarchiver unarchiveObjectWithData:data] count] == 0);
}

- (void)testClearSessionHistoryExceptCurrentOne {

  // When
  [[MSSessionContext sharedInstance] setSessionId:@"Session1"];
  [MSSessionContext resetSharedInstance];
  [[MSSessionContext sharedInstance] setSessionId:@"Session2"];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertTrue([[NSKeyedUnarchiver unarchiveObjectWithData:data] count] == 2);

  // When
  [[MSSessionContext sharedInstance] clearSessionHistoryAndKeepCurrentSession:YES];

  // Then
  data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);

  // Should keep the current session.
  XCTAssertTrue([[NSKeyedUnarchiver unarchiveObjectWithData:data] count] == 1);
}

- (void)testSessionId {

  // If
  NSString *expectedSessionId = @"Session";

  // When
  [[MSSessionContext sharedInstance] setSessionId:expectedSessionId];

  // Then
  XCTAssertEqualObjects(expectedSessionId, [[MSSessionContext sharedInstance] sessionId]);
}

- (void)testSessionIdAt {

  // If
  __block NSDate *date;
  id dateMock = OCMClassMock([NSDate class]);

  // When
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    [invocation setReturnValue:&date];
  });
  [[MSSessionContext sharedInstance] setSessionId:@"Session1"];
  [dateMock stopMocking];

  [MSSessionContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:1000];
    [invocation setReturnValue:&date];
  });
  [[MSSessionContext sharedInstance] setSessionId:@"Session2"];
  [dateMock stopMocking];

  [MSSessionContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:2000];
    [invocation setReturnValue:&date];
  });
  [[MSSessionContext sharedInstance] setSessionId:@"Session3"];
  [dateMock stopMocking];

  [MSSessionContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:3000];
    [invocation setReturnValue:&date];
  });
  [[MSSessionContext sharedInstance] setSessionId:@"Session4"];
  [dateMock stopMocking];

  [MSSessionContext resetSharedInstance];

  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:4000];
    [invocation setReturnValue:&date];
  });
  [[MSSessionContext sharedInstance] setSessionId:@"Session5"];
  [dateMock stopMocking];

  // Then
  XCTAssertNil([[MSSessionContext sharedInstance] sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:0]]);
  XCTAssertEqualObjects(@"Session3", [[MSSessionContext sharedInstance] sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:2500]]);
  XCTAssertEqualObjects(@"Session5", [[MSSessionContext sharedInstance] sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:5000]]);
}

@end
