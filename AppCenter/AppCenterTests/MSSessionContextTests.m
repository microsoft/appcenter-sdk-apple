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
  [MSSessionContext setSessionId:expectedSessionId];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertEqualObjects([[NSKeyedUnarchiver unarchiveObjectWithData:data][0] sessionId], expectedSessionId);
}

- (void)testClearSessionHistory {

  // When
  [MSSessionContext setSessionId:@"Session1"];
  [MSSessionContext resetSharedInstance];
  [MSSessionContext setSessionId:@"Session2"];

  // Then
  NSData *data = [self.settingsMock objectForKey:@"SessionIdHistory"];
  XCTAssertNotNil(data);
  XCTAssertTrue([[NSKeyedUnarchiver unarchiveObjectWithData:data] count] == 2);

  // When
  [MSSessionContext clearSessionHistory];

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
  [MSSessionContext setSessionId:expectedSessionId];

  // Then
  XCTAssertEqualObjects(expectedSessionId, [MSSessionContext sessionId]);
}

- (void)testSessionIdAt {

  // If
  __block int counter = 0;
  __block NSDate *date;
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:1000 * ++counter];
    [invocation setReturnValue:(__bridge void * _Nonnull)date];
  });

  // When
  [MSSessionContext setSessionId:@"Session1"];
  [MSSessionContext resetSharedInstance];
  [MSSessionContext setSessionId:@"Session2"];
  [MSSessionContext resetSharedInstance];
  [MSSessionContext setSessionId:@"Session3"];
  [MSSessionContext resetSharedInstance];
  [MSSessionContext setSessionId:@"Session4"];
  [MSSessionContext resetSharedInstance];
  [MSSessionContext setSessionId:@"Session5"];

  // Then
  // resetSharedInstance will also call [NSDate date] so timestamp 5500 should return "Session3"
  XCTAssertNil([MSSessionContext sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:0]]);
  XCTAssertEqualObjects(@"Session3",
                        [MSSessionContext sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:5500]]);
  XCTAssertEqualObjects(@"Session5",
                        [MSSessionContext sessionIdAt:[[NSDate alloc] initWithTimeIntervalSince1970:10000]]);

  [dateMock stopMocking];
}

@end
