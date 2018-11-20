#import <Foundation/Foundation.h>

#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

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
  XCTAssertEqualObjects([[NSKeyedUnarchiver unarchiveObjectWithData:data][0] userId], expectedUserId);
}

- (void)testClearUserIdHistory {

  // When
  [[MSUserIdContext sharedInstance] setUserId:@"UserId1"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId2"];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"UserIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertEqual([[NSKeyedUnarchiver unarchiveObjectWithData:data] count], 2);

  // When
  [[MSUserIdContext sharedInstance] clearUserIdHistory];

  // Then
  data = [self.settingsMock objectForKey:@"UserIdHistory"];
  XCTAssertNotNil(data);

  // Should keep the current userId.
  XCTAssertEqual([[NSKeyedUnarchiver unarchiveObjectWithData:data] count], 1);
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
  __block int counter = 0;
  __block NSDate *date;
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:1000 * ++counter];
    [invocation setReturnValue:&date];
  });

  // When
  [[MSUserIdContext sharedInstance] setUserId:@"UserId1"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId2"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId3"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId4"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"UserId5"];

  // Then
  // sharedInstance will also call [NSDate date] so timestamp 5500 should return "UserId3"
  XCTAssertNil([[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:0]]);
  XCTAssertEqualObjects(@"UserId3", [[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:5500]]);
  XCTAssertEqualObjects(@"UserId5", [[MSUserIdContext sharedInstance] userIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:10000]]);

  [dateMock stopMocking];
}

@end
