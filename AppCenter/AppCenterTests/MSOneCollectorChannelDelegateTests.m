#import "MSCSExtensions.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelUnitProtocol.h"
#import "MSCommonSchemaLog.h"
#import "MSIngestionProtocol.h"
#import "MSMockLogObject.h"
#import "MSMockLogWithConversion.h"
#import "MSOneCollectorChannelDelegatePrivate.h"
#import "MSSDKExtension.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"

static NSString *const kMSBaseGroupId = @"baseGroupId";

@interface MSOneCollectorChannelDelegateTests : XCTestCase

@property(nonatomic) MSOneCollectorChannelDelegate *sut;
@property(nonatomic) id<MSIngestionProtocol> ingestionMock;
@property(nonatomic) id<MSStorage> storageMock;
@property(nonatomic) dispatch_queue_t logsDispatchQueue;
@property(nonatomic) MSChannelUnitConfiguration *baseUnitConfigMock;

@end

@implementation MSOneCollectorChannelDelegateTests

- (void)setUp {
  [super setUp];
  self.sut =
      [[MSOneCollectorChannelDelegate alloc] initWithInstallId:[NSUUID new]];
  self.ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  self.logsDispatchQueue = dispatch_get_main_queue();
  self.baseUnitConfigMock =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSBaseGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
}

- (void)testDidAddChannelUnitWithBaseGroupId {

  // Test adding a base channel unit on MSChannelGroupDefault will also add a
  // One Collector channel unit.

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *expectedGroupId = @"baseGroupId/one";

  OCMStub([channelUnitMock configuration]).andReturn(self.baseUnitConfigMock);
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block id<MSChannelUnitProtocol> expectedChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  __block MSChannelUnitConfiguration *oneCollectorChannelConfig = nil;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments];
        [invocation getArgument:&oneCollectorChannelConfig atIndex:2];
        [invocation setReturnValue:&expectedChannelUnitMock];
      });

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];

  // Then
  XCTAssertNotNil(self.sut.oneCollectorChannels[kMSBaseGroupId]);
  XCTAssertTrue([self.sut.oneCollectorChannels count] == 1);
  XCTAssertEqual(expectedChannelUnitMock,
                 self.sut.oneCollectorChannels[kMSBaseGroupId]);
  XCTAssertTrue(
      [oneCollectorChannelConfig.groupId isEqualToString:expectedGroupId]);
  OCMVerifyAll(channelGroupMock);
}

- (void)testDidAddChannelUnitWithOneCollectorGroupId {

  /*
   * Test adding an One Collector channel unit on MSChannelGroupDefault won't do
   * anything on MSOneCollectorChannelDelegate because it's already an One
   * Collector group Id.
   */

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
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

- (void)testDidSetEnabledAndDeleteDataOnDisabledWithBaseGroupId {

  /*
   * Test base channel unit's logs are cleared when the base channel unit is
   * disabled. First, add a base channel unit to the channel group. Then,
   * disable the base channel unit. Lastly, verify the storage deletion is
   * called for the base channel group id.
   */

  // If
  MSChannelUnitDefault *channelUnitMock =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:self.storageMock
                                        configuration:self.baseUnitConfigMock
                                    logsDispatchQueue:self.logsDispatchQueue];
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock
      addChannelUnitWithConfiguration:self.baseUnitConfigMock]);
  OCMStub([channelUnitMock setEnabled:NO andDeleteDataOnDisabled:YES]);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
                didSetEnabled:NO
      andDeleteDataOnDisabled:YES];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([self.storageMock
                                     deleteLogsWithGroupId:kMSBaseGroupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDidSetEnabledAndDeleteDataOnDisabledWithOneCollectorGroupId {

  /*
   * Test One Collector channel unit's logs are cleared when the One Collector
   * channel unit is disabled. Disable One Collector channel unit. Verify the
   * storage deletion is called for the One Collector channel group id.
   */

  // If
  NSString *oneCollectorGroupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *oneCollectorUnitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:oneCollectorGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];

  MSChannelUnitDefault *oneCollectorChannelUnitMock =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:self.storageMock
                                        configuration:oneCollectorUnitConfig
                                    logsDispatchQueue:self.logsDispatchQueue];
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMReject([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]);
  OCMStub(
      [oneCollectorChannelUnitMock setEnabled:NO andDeleteDataOnDisabled:YES]);

  // When
  [self.sut channel:oneCollectorChannelUnitMock
                didSetEnabled:NO
      andDeleteDataOnDisabled:YES];

  // Then
  XCTAssertTrue(self.sut.oneCollectorChannels.count == 0);
  [self enqueueChannelEndJobExpectation];
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               OCMVerify([self.storageMock
                                   deleteLogsWithGroupId:oneCollectorGroupId]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
                               }
                             }];
}

- (void)
    testDidEnqueueLogToOneCollectorChannelWhenLogHasTargetTokensAndLogIsNotCommonSchemaLog {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub(oneCollectorChannelUnitMock.logsDispatchQueue)
      .andReturn(self.logsDispatchQueue);
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  [transmissionTargetTokens addObject:@"fake-transmission-target-token"];
  MSCommonSchemaLog *commonSchemaLog = [MSCommonSchemaLog new];
  id<MSMockLogWithConversion> mockLog =
      OCMProtocolMock(@protocol(MSMockLogWithConversion));
  OCMStub([mockLog toCommonSchemaLogs]).andReturn(@[ commonSchemaLog ]);
  OCMStub(mockLog.transmissionTargetTokens).andReturn(transmissionTargetTokens);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
       didPrepareLog:mockLog
      withInternalId:@"fake-id"];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([oneCollectorChannelUnitMock
                                     enqueueItem:commonSchemaLog]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)
    testDidNotEnqueueLogToOneCollectorChannelWhenLogDoesNotConformToMSLogConversionProtocol {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  [transmissionTargetTokens addObject:@"fake-transmission-target-token"];
  MSCommonSchemaLog *commonSchemaLog = [MSCommonSchemaLog new];
  id<MSMockLogObject> mockLog = OCMProtocolMock(@protocol(MSMockLogObject));
  OCMStub(mockLog.transmissionTargetTokens).andReturn(transmissionTargetTokens);

  // Then
  OCMReject([oneCollectorChannelUnitMock enqueueItem:commonSchemaLog]);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
       didPrepareLog:mockLog
      withInternalId:@"fake-id"];
}

- (void)testReEnqueueLogWhenCommonSchemaLogIsPrepared {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub(oneCollectorChannelUnitMock.logsDispatchQueue)
      .andReturn(self.logsDispatchQueue);
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  [transmissionTargetTokens addObject:@"fake-transmission-target-token"];
  id<MSLog> commonSchemaLog = [MSCommonSchemaLog new];
  OCMStub(commonSchemaLog.transmissionTargetTokens)
      .andReturn(transmissionTargetTokens);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
       didPrepareLog:commonSchemaLog
      withInternalId:@"fake-id"];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([oneCollectorChannelUnitMock
                                     enqueueItem:commonSchemaLog]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDidNotEnqueueLogWhenLogHasNoTargetTokens {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  id<MSMockLogWithConversion> mockLog =
      OCMProtocolMock(@protocol(MSMockLogWithConversion));
  OCMStub(mockLog.transmissionTargetTokens).andReturn(transmissionTargetTokens);
  OCMStub([mockLog toCommonSchemaLogs]).andReturn(@[ [MSCommonSchemaLog new] ]);
  OCMStub([mockLog isKindOfClass:[MSCommonSchemaLog class]]).andReturn(NO);

  // Then
  OCMReject([oneCollectorChannelUnitMock enqueueItem:OCMOCK_ANY]);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
       didPrepareLog:mockLog
      withInternalId:@"fake-id"];
}

- (void)testDidNotEnqueueLogWhenLogHasNilTargetTokens {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  id<MSMockLogWithConversion> mockLog =
      OCMProtocolMock(@protocol(MSMockLogWithConversion));
  OCMStub([mockLog isKindOfClass:[MSCommonSchemaLog class]]).andReturn(NO);
  OCMStub(mockLog.transmissionTargetTokens).andReturn(nil);
  OCMStub([mockLog toCommonSchemaLogs]).andReturn(@[ [MSCommonSchemaLog new] ]);

  // Then
  OCMReject([oneCollectorChannelUnitMock enqueueItem:OCMOCK_ANY]);

  // When
  [self.sut channelGroup:channelGroupMock didAddChannelUnit:channelUnitMock];
  [self.sut channel:channelUnitMock
       didPrepareLog:mockLog
      withInternalId:@"fake-id"];
}

- (void)testDoesNotFilterValidCommonSchemaLogs {

  // If
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([oneCollectorChannelUnitMock configuration]).andReturn(unitConfig);
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.name = @"avalidname";

  // When
  BOOL shouldFilter =
      [self.sut channelUnit:oneCollectorChannelUnitMock shouldFilterLog:log];

  // Then
  XCTAssertFalse(shouldFilter);
}

- (void)testFiltersInvalidCommonSchemaLogs {

  // If
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId/one";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([oneCollectorChannelUnitMock configuration]).andReturn(unitConfig);
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.name = nil;

  // When
  BOOL shouldFilter =
      [self.sut channelUnit:oneCollectorChannelUnitMock shouldFilterLog:log];

  // Then
  XCTAssertTrue(shouldFilter);
}

- (void)testDoesNotFilterLogFromNonOneCollectorChannelWhenLogHasNoTargetTokens {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  id<MSLog> mockLog = OCMProtocolMock(@protocol(MSLog));
  OCMStub(mockLog.transmissionTargetTokens).andReturn(transmissionTargetTokens);

  // When
  BOOL shouldFilter =
      [self.sut channelUnit:channelUnitMock shouldFilterLog:mockLog];

  // Then
  XCTAssertFalse(shouldFilter);
}

- (void)
    testDoesNotFilterLogFromNonOneCollectorChannelWhenLogHasNilTargetTokenSet {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSLog> mockLog = OCMProtocolMock(@protocol(MSLog));
  OCMStub(mockLog.transmissionTargetTokens).andReturn(nil);

  // When
  BOOL shouldFilter =
      [self.sut channelUnit:channelUnitMock shouldFilterLog:mockLog];

  // Then
  XCTAssertFalse(shouldFilter);
}

- (void)testFiltersNonOneCollectorLogWhenLogHasTargetTokens {

  // If
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  NSString *groupId = @"baseGroupId";
  MSChannelUnitConfiguration *unitConfig =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                 priority:MSPriorityDefault
                                            flushInterval:3.0
                                           batchSizeLimit:1024
                                      pendingBatchesLimit:60];
  OCMStub([channelUnitMock configuration]).andReturn(unitConfig);
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY
                                              withIngestion:OCMOCK_ANY])
      .andReturn(oneCollectorChannelUnitMock);
  NSMutableSet *transmissionTargetTokens = [NSMutableSet new];
  [transmissionTargetTokens addObject:@"fake-transmission-target-token"];
  MSCommonSchemaLog *commonSchemaLog = [MSCommonSchemaLog new];
  id<MSMockLogWithConversion> mockLog =
      OCMProtocolMock(@protocol(MSMockLogWithConversion));
  OCMStub([mockLog toCommonSchemaLogs]).andReturn(@[ commonSchemaLog ]);
  OCMStub(mockLog.transmissionTargetTokens).andReturn(transmissionTargetTokens);

  // When
  BOOL shouldFilter =
      [self.sut channelUnit:channelUnitMock shouldFilterLog:mockLog];

  // Then
  XCTAssertTrue(shouldFilter);
}

- (void)testValidateLog {

  // If
  // Valid name.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.name = @"valid.CS.event.name";

  // Then
  XCTAssertTrue([self.sut validateLog:log]);

  // If
  // Invalid name.
  log.name = nil;

  // Then
  XCTAssertFalse([self.sut validateLog:log]);

  // If
  // Valid data.
  log.name = @"valid.CS.event.name";
  log.data = [MSCSData new];
  log.data.properties = @{ @"validkey" : @"validvalue" };

  // Then
  XCTAssertTrue([self.sut validateLog:log]);

  // If
  // Invalid data.
  log.data.properties = @{ @(24) : @(42) };

  // Then
  XCTAssertFalse([self.sut validateLog:log]);
}

- (void)testValidateLogName {
  const int maxNameLength = 100;

  // If
  NSString *validName = @"valid.CS.event.name";
  NSString *shortName = @"e";
  NSString *name100 = [@"" stringByPaddingToLength:maxNameLength
                                         withString:@"logName100"
                                    startingAtIndex:0];
  NSString *nilLogName = nil;
  NSString *emptyName = @"";
  NSString *tooLongName = [@"" stringByPaddingToLength:(maxNameLength + 1)
                                             withString:@"tooLongLogName"
                                        startingAtIndex:0];
  NSString *periodAndUnderscoreName = @"hello.world_mamamia";
  NSString *leadingPeriodName = @".hello.world";
  NSString *trailingPeriodName = @"hello.world.";
  NSString *consecutivePeriodName = @"hello..world";
  NSString *headingUnderscoreName = @"_hello.world";
  NSString *specialCharactersOtherThanPeriodAndUnderscore = @"hello%^&world";

  // Then
  XCTAssertTrue([self.sut validateLogName:validName]);
  XCTAssertFalse([self.sut validateLogName:shortName]);
  XCTAssertTrue([self.sut validateLogName:name100]);
  XCTAssertFalse([self.sut validateLogName:nilLogName]);
  XCTAssertFalse([self.sut validateLogName:emptyName]);
  XCTAssertFalse([self.sut validateLogName:tooLongName]);
  XCTAssertTrue([self.sut validateLogName:periodAndUnderscoreName]);
  XCTAssertFalse([self.sut validateLogName:leadingPeriodName]);
  XCTAssertFalse([self.sut validateLogName:trailingPeriodName]);
  XCTAssertFalse([self.sut validateLogName:consecutivePeriodName]);
  XCTAssertFalse([self.sut validateLogName:headingUnderscoreName]);
  XCTAssertFalse(
      [self.sut validateLogName:specialCharactersOtherThanPeriodAndUnderscore]);
}

- (void)testValidateLogData {

  // If
  MSCSData *newData = [MSCSData new];
  MSCSData *nilData = nil;
  MSCSData *nilDataPropsWithEmptyKey = [MSCSData new];
  nilDataPropsWithEmptyKey.properties = @{ @"" : @"avalidvalue" };
  MSCSData *nilDataPropsWithNonStringKey = [MSCSData new];
  nilDataPropsWithNonStringKey.properties = @{ @(42) : @"avalidvalue" };
  MSCSData *nilDataPropsWithEmptyValue = [MSCSData new];
  nilDataPropsWithEmptyValue.properties = @{ @"avalidkey" : @"" };
  MSCSData *nilDataPropsWithNonStringValue = [MSCSData new];
  nilDataPropsWithNonStringValue.properties = @{ @"avalidkey" : @(42) };

  // Then
  XCTAssertTrue([self.sut validateLogData:newData]);
  XCTAssertTrue([self.sut validateLogData:nilData]);
  XCTAssertTrue([self.sut validateLogData:nilDataPropsWithEmptyKey]);
  XCTAssertFalse([self.sut validateLogData:nilDataPropsWithNonStringKey]);
  XCTAssertTrue([self.sut validateLogData:nilDataPropsWithEmptyValue]);
  XCTAssertFalse([self.sut validateLogData:nilDataPropsWithNonStringValue]);
}

- (void)testLogNameRegex {

  // If
  NSError *error = nil;

  // When
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:kMSLogNameRegex
                                                options:0
                                                  error:&error];

  // Then
  XCTAssertNotNil(regex);
  XCTAssertNil(error);
}

- (void)testPrepareLogForSDKExtension {

  // If
  NSUUID *installId = [NSUUID new];
  self.sut =
      [[MSOneCollectorChannelDelegate alloc] initWithInstallId:installId];
  id channelMock = OCMProtocolMock(@protocol(MSChannelProtocol));
  MSCommonSchemaLog *csLogMock = OCMPartialMock([MSCommonSchemaLog new]);
  csLogMock.iKey = @"o:81439696f7164d7599d543f9bf37abb7";
  MSCSExtensions *ext = OCMPartialMock([MSCSExtensions new]);
  MSSDKExtension *sdkExt = OCMPartialMock([MSSDKExtension new]);
  ext.sdkExt = sdkExt;
  csLogMock.ext = ext;
  OCMStub([csLogMock isValid]).andReturn(YES);

  // When
  [self.sut channel:channelMock prepareLog:csLogMock];

  // Then
  XCTAssertEqualObjects(installId, csLogMock.ext.sdkExt.installId);
  XCTAssertNotNil(csLogMock.ext.sdkExt.epoch);
  XCTAssertEqual(csLogMock.ext.sdkExt.seq, 1);
  XCTAssertNotNil(self.sut.epochsAndSeqsByIKey);
  XCTAssertTrue(self.sut.epochsAndSeqsByIKey.count == 1);
}

- (void)testResetEpochAndSeq {

  // If
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  MSCommonSchemaLog *csLogMock = OCMPartialMock([MSCommonSchemaLog new]);
  csLogMock.iKey = @"o:81439696f7164d7599d543f9bf37abb7";
  MSCSExtensions *ext = OCMPartialMock([MSCSExtensions new]);
  MSSDKExtension *sdkExt = OCMPartialMock([MSSDKExtension new]);
  ext.sdkExt = sdkExt;
  csLogMock.ext = ext;
  OCMStub([csLogMock isValid]).andReturn(YES);

  // When
  [self.sut channel:channelGroupMock prepareLog:csLogMock];

  // Then
  XCTAssertNotNil(self.sut.epochsAndSeqsByIKey);
  XCTAssertTrue(self.sut.epochsAndSeqsByIKey.count == 1);

  // When
  [self.sut channel:channelGroupMock
                didSetEnabled:NO
      andDeleteDataOnDisabled:YES];

  // Then
  XCTAssertTrue(self.sut.epochsAndSeqsByIKey.count == 0);
}

// A helper method to initialize the test expectation
- (void)enqueueChannelEndJobExpectation {
  XCTestExpectation *channelEndJobExpectation =
      [self expectationWithDescription:@"Channel job should be finished"];
  dispatch_async(self.logsDispatchQueue, ^{
    [channelEndJobExpectation fulfill];
  });
}
@end
