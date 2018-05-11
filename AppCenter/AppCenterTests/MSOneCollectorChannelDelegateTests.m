#import <XCTest/XCTest.h>
#import "MSOneCollectorChannelDelegatePrivate.h"
#import "MSChannelUnitProtocol.h"
#import "MSChannelUnitDefault.h"
#import "MSTestFrameworks.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelGroupProtocol.h"

@interface MSOneCollectorChannelDelegateTests : XCTestCase

@property(nonatomic) MSOneCollectorChannelDelegate *sut;

@end

@implementation MSOneCollectorChannelDelegateTests

- (void)setUp {
  [super setUp];
  self.sut = [[MSOneCollectorChannelDelegate alloc] init];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testDidAddChannelUnitWithBaseGroupId {

  // Test adding an base channel unit on MSChannelGroupDefault will also add a One Collector channel unit.

  // If
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  NSString *expectedGroupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *unitConfig = [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                                      priority:MSPriorityDefault
                                                                                 flushInterval:3.0
                                                                                batchSizeLimit:1024
                                                                           pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block id<MSChannelUnitProtocol> expectedChannelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  __block MSChannelUnitConfiguration *oneCollectorChannelConfig = nil;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];
    [invocation getArgument:&oneCollectorChannelConfig atIndex:2];
    [invocation setReturnValue:&expectedChannelUnitMock];
  });

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];

  // Then
  XCTAssertNotNil(self.sut.oneCollectorChannels[groupId]);
  XCTAssertTrue([self.sut.oneCollectorChannels count] == 1);
  XCTAssertEqual(expectedChannelUnitMock, self.sut.oneCollectorChannels[groupId]);
  XCTAssertTrue([oneCollectorChannelConfig.groupId isEqualToString:expectedGroupId]);
  OCMVerifyAll(channelGroupMock);
}

- (void)testDidAddChannelUnitWithOneCollectorGroupId {

  /*
   * Test adding an One Collector channel unit on MSChannelGroupDefault won't do anything on
   * MSOneCollectorChannelDelegate
   * because it's already an One Collector group Id.
   */

  // If
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *unitConfig = [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                                      priority:MSPriorityDefault
                                                                                 flushInterval:3.0
                                                                                batchSizeLimit:1024
                                                                           pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMReject([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];

  // Then
  XCTAssertNotNil(self.sut.oneCollectorChannels);
  XCTAssertTrue([self.sut.oneCollectorChannels count] == 0);
  OCMVerifyAll(channelGroupMock);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}

@end
