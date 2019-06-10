// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSAppCenter.h"
#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSAuthTokenInfo.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSChannelDelegate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelUnitDefaultPrivate.h"
#import "MSDevice.h"
#import "MSDispatchTestUtil.h"
#import "MSHttpIngestion.h"
#import "MSHttpTestUtil.h"
#import "MSLogContainer.h"
#import "MSMockUserDefaults.h"
#import "MSServiceCommon.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContext.h"
#import "MSUtility.h"

static NSTimeInterval const kMSTestTimeout = 1.0;
static NSString *const kMSTestGroupId = @"GroupId";

@interface MSChannelUnitDefault (Test)

- (void)sendLogContainer:(MSLogContainer *__nonnull)container
    withAuthTokenFromArray:(NSArray<MSAuthTokenValidityInfo *> *__nonnull)tokenArray
                   atIndex:(NSUInteger)tokenIndex;

- (void)flushQueueForTokenArray:(NSArray<MSAuthTokenValidityInfo *> *)tokenArray withTokenIndex:(NSUInteger)tokenIndex;

@end

@interface MSChannelUnitDefaultTests : XCTestCase

@property(nonatomic) MSChannelUnitConfiguration *configuration;
@property(nonatomic) MSMockUserDefaults *settingsMock;

@property(nonatomic) MSChannelUnitDefault *sut;

@property(nonatomic) dispatch_queue_t logsDispatchQueue;

@property(nonatomic) id storageMock;
@property(nonatomic) id ingestionMock;
@property(nonatomic) id authTokenContextMock;

/**
 * Most of the channel APIs are asynchronous, this expectation is meant to be enqueued to the data dispatch queue at the end of the test
 * before any asserts. Then it will be triggered on the next queue loop right after the channel finished its job. Wrap asserts within the
 * handler of a waitForExpectationsWithTimeout method.
 */
@property(nonatomic) XCTestExpectation *channelEndJobExpectation;

@end

@implementation MSChannelUnitDefaultTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];

  /*
   * dispatch_get_main_queue isn't good option for logsDispatchQueue because
   * we can't clear pending actions from it after the test. It can cause usages of stopped mocks.
   */
  self.logsDispatchQueue = dispatch_queue_create("com.microsoft.appcenter.ChannelGroupQueue", DISPATCH_QUEUE_SERIAL);
  self.configuration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:kMSTestGroupId];
  self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsNormal]).andReturn(YES);
  OCMStub([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsCritical]).andReturn(YES);
  self.ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMStub([self.ingestionMock isReadyToSend]).andReturn(YES);
  self.sut = [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                                     storage:self.storageMock
                                               configuration:self.configuration
                                           logsDispatchQueue:self.logsDispatchQueue];
  self.settingsMock = [MSMockUserDefaults new];

  // Auth token context.
  [MSAuthTokenContext resetSharedInstance];
  self.authTokenContextMock = OCMClassMock([MSAuthTokenContext class]);
  OCMStub([self.authTokenContextMock sharedInstance]).andReturn(self.authTokenContextMock);
  OCMStub([self.authTokenContextMock authTokenValidityArray]).andReturn(@ [[MSAuthTokenValidityInfo new]]);
}

- (void)tearDown {
  [MSDispatchTestUtil awaitAndSuspendDispatchQueue:self.logsDispatchQueue];

  // Stop mocks.
  [self.settingsMock stopMocking];
  [self.authTokenContextMock stopMocking];
  [MSAuthTokenContext resetSharedInstance];
  [super tearDown];
}

#pragma mark - Tests

- (void)testPendingLogsStoresStartTimeWhenPaused {

  // If
  [self initChannelEndJobExpectation];
  id dateMock = OCMClassMock([NSDate class]);
  NSObject *object = [NSObject new];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:3000];
  OCMStub([dateMock date]).andReturn(date);

  // Configure channel with custom interval.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:60
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:3];

  // When
  [self.sut pauseWithIdentifyingObjectSync:object];

  // Trigger checkPengingLogs. Should save timestamp now.
  [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 NSDate *resultDate = [self.settingsMock objectForKey:self.sut.oldestPendingLogTimestampKey];
                                 XCTAssertTrue([date isEqualToDate:resultDate]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [dateMock stopMocking];
}

- (void)testCustomFlushIntervalSending200Logs {

  // If
  [self initChannelEndJobExpectation];
  NSUInteger flushInterval = 600;
  NSUInteger batchSizeLimit = 50;
  __block int currentBatchId = 1;
  id dateMock = OCMClassMock([NSDate class]);
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
  NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:flushInterval + 100];
  __block id responseMock = [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil];
  __block MSSendAsyncCompletionHandler ingestionBlock;

  // Requests counter.
  __block int sendCount = 0;
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
    sendCount++;
  });

  // Stub the storage load.
  NSArray<id<MSLog>> *logs = [self getValidMockLogArrayForDate:date andCount:50];
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionHandler loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:7];

        // Mock load with incrementing batchId.
        loadCallback(logs, [@(currentBatchId++) stringValue]);

        // Return YES and exit the method.
        BOOL enabled = YES;
        [invocation setReturnValue:&enabled];
      });

  // Configure channel and set custom flushInterval.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:flushInterval
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:3];

  // When
  self.sut.itemsCount = 200;

  // Timestamp saved with time == 0.
  [self.settingsMock setObject:date forKey:self.sut.oldestPendingLogTimestampKey];

  // Change time. Simulate time has passed.
  OCMStub([dateMock date]).andReturn(date2);

  // Trigger checkPengingLogs. Should flush 3 batches now.
  [self.sut checkPendingLogs];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    // Check 3 batches sent.
    assertThatInt(sendCount, equalToInt(3));
    XCTAssertNotNil(ingestionBlock);
    if (ingestionBlock) {

      // Release 1 batch.
      ingestionBlock([@(1) stringValue], responseMock, nil, nil);
    }

    // Then
    dispatch_async(self.logsDispatchQueue, ^{
      // Check 4th batch sent.
      assertThatInt(sendCount, equalToInt(4));

      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [dateMock stopMocking];
  [responseMock stopMocking];
}

- (void)testLogsFlushedImmediatelyWhenIntervalIsOver {

  // If
  [self initChannelEndJobExpectation];
  id dateMock = OCMClassMock([NSDate class]);
  self.sut.itemsCount = 5;

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:600
                                                                batchSizeLimit:1
                                                           pendingBatchesLimit:3];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:3000];
  OCMStub([dateMock date]).andReturn(date);
  [self.settingsMock setObject:[[NSDate alloc] initWithTimeIntervalSince1970:500] forKey:self.sut.oldestPendingLogTimestampKey];
  id channelUnitMock = OCMPartialMock(self.sut);
  OCMReject([channelUnitMock startTimer:OCMOCK_ANY]);

  // When
  // Trigger checkPendingLogs
  [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                                 OCMVerify([self.sut flushQueue]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [dateMock stopMocking];
  [channelUnitMock stopMocking];
}

- (void)testLogsNotFlushedImmediatelyWhenIntervalIsCustom {

  // If
  [self initChannelEndJobExpectation];
  id channelmock = OCMPartialMock(self.sut);
  NSUInteger batchSizeLimit = 4;
  int itemsToAdd = 8;
  NSUInteger flushInterval = 600;

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:flushInterval
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:3];

  // When
  for (NSUInteger i = 0; i < itemsToAdd; i++) {
    [channelmock enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  }
  // Then
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify([channelmock startTimer:OCMOCK_ANY]);
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [channelmock stopMocking];
}

- (void)testResolveFlushIntervalTimestampNotSet {

  // If
  id dateMock = OCMClassMock([NSDate class]);
  NSUInteger flushInterval = 2000;

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:flushInterval
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:1];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:1000];
  OCMStub([dateMock date]).andReturn(date);

  // When
  NSUInteger resultFlushInterval = [self.sut resolveFlushInterval];

  // Then
  XCTAssertEqual(resultFlushInterval, flushInterval);

  // Clear
  [dateMock stopMocking];
}

- (void)testResolveFlushIntervalTimeIsOut {

  // If
  id dateMock = OCMClassMock([NSDate class]);
  NSUInteger flushInterval = 2000;

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:flushInterval
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:1];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:3000];
  OCMStub([dateMock date]).andReturn(date);
  [self.settingsMock setObject:[[NSDate alloc] initWithTimeIntervalSince1970:500] forKey:self.sut.oldestPendingLogTimestampKey];

  // When
  NSUInteger resultFlushInterval = [self.sut resolveFlushInterval];

  // Then
  XCTAssertEqual(resultFlushInterval, 0);

  // Clear
  [dateMock stopMocking];
}

- (void)testResolveFlushIntervalTimestampLaterThanNow {

  // If
  id dateMock = OCMClassMock([NSDate class]);
  NSUInteger flushInterval = 2000;

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:flushInterval
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:1];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:1000];
  OCMStub([dateMock date]).andReturn(date);
  [self.settingsMock setObject:[[NSDate alloc] initWithTimeIntervalSince1970:2000] forKey:self.sut.oldestPendingLogTimestampKey];

  // When
  NSUInteger resultFlushInterval = [self.sut resolveFlushInterval];

  // Then
  XCTAssertEqual(resultFlushInterval, flushInterval);

  // Clear
  [dateMock stopMocking];
}

- (void)testResolveFlushIntervalNow {

  // If
  id dateMock = OCMClassMock([NSDate class]);

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:2000
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:1];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:4000];
  OCMStub([dateMock date]).andReturn(date);
  [self.settingsMock setObject:[[NSDate alloc] initWithTimeIntervalSince1970:2000] forKey:self.sut.oldestPendingLogTimestampKey];

  // When
  NSUInteger resultFlushInterval = [self.sut resolveFlushInterval];

  // Then
  XCTAssertEqual(resultFlushInterval, 0);

  // Clear
  [dateMock stopMocking];
}

- (void)testResolveFlushInterval {

  // If
  id dateMock = OCMClassMock([NSDate class]);

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:2000
                                                                batchSizeLimit:50
                                                           pendingBatchesLimit:1];
  NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:1000];
  OCMStub([dateMock date]).andReturn(date);
  [self.settingsMock setObject:[[NSDate alloc] initWithTimeIntervalSince1970:500] forKey:self.sut.oldestPendingLogTimestampKey];

  // When
  NSUInteger resultFlushInterval = [self.sut resolveFlushInterval];

  // Then
  XCTAssertEqual(resultFlushInterval, 1500);

  // Clear
  [dateMock stopMocking];
}

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.configuration, equalTo(self.configuration));
  assertThat(self.sut.ingestion, equalTo(self.ingestionMock));
  assertThat(self.sut.storage, equalTo(self.storageMock));
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
  OCMVerify([self.ingestionMock addDelegate:self.sut]);
}

- (void)testLogsSentWithSuccess {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  NSUInteger batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  __block NSString *actualAuthToken;
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&logContainer atIndex:2];
    [invocation getArgument:&actualAuthToken atIndex:3];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  __block id responseMock = [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil];

  // Stub the storage load for that log.
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionHandler loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:7];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:1];

  [self.sut addDelegate:delegateMock];
  OCMReject([delegateMock channel:self.sut didFailSendingLog:OCMOCK_ANY withError:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:self.sut didSucceedSendingLog:expectedLog]);
  OCMExpect([delegateMock channel:self.sut prepareLog:enqueuedLog]);
  OCMExpect([delegateMock channel:self.sut didPrepareLog:enqueuedLog internalId:OCMOCK_ANY flags:MSFlagsDefault]);
  OCMExpect([delegateMock channel:self.sut didCompleteEnqueueingLog:enqueuedLog internalId:OCMOCK_ANY]);
  OCMExpect([self.storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  // When
  dispatch_async(self.logsDispatchQueue, ^{
    // Enqueue now that the delegate is set.
    [self.sut enqueueItem:enqueuedLog flags:MSFlagsDefault];

    // Try to release one batch.
    dispatch_async(self.logsDispatchQueue, ^{
      XCTAssertNotNil(ingestionBlock);
      if (ingestionBlock) {
        ingestionBlock([@(1) stringValue], responseMock, nil, nil);
      }

      // Then
      dispatch_async(self.logsDispatchQueue, ^{
        [self enqueueChannelEndJobExpectation];
      });
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Get sure it has been sent.
                                 assertThat(logContainer.batchId, is(expectedBatchId));
                                 assertThat(logContainer.logs, is(@[ expectedLog ]));
                                 assertThatBool(self.sut.pendingBatchQueueFull, isFalse());
                                 assertThatUnsignedLong(self.sut.pendingBatchIds.count, equalToUnsignedLong(0));
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(self.storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNil(actualAuthToken);
                               }];
  [responseMock stopMocking];
}

- (void)testLogsSentWithFailure {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  NSUInteger batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
    [invocation getArgument:&logContainer atIndex:2];
  });
  __block id responseMock = [MSHttpTestUtil createMockResponseForStatusCode:300 headers:nil];

  // Stub the storage load for that log.
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionHandler loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:7];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:1];
  [self.sut addDelegate:delegateMock];
  OCMExpect([delegateMock channel:self.sut didFailSendingLog:expectedLog withError:OCMOCK_ANY]);
  OCMReject([delegateMock channel:self.sut didSucceedSendingLog:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:self.sut didPrepareLog:enqueuedLog internalId:OCMOCK_ANY flags:MSFlagsDefault]);
  OCMExpect([delegateMock channel:self.sut didCompleteEnqueueingLog:enqueuedLog internalId:OCMOCK_ANY]);

  // The logs shouldn't be deleted after recoverable error.
  OCMReject([self.storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  // When
  dispatch_async(self.logsDispatchQueue, ^{
    // Enqueue now that the delegate is set.
    [self.sut enqueueItem:enqueuedLog flags:MSFlagsDefault];

    // Try to release one batch.
    dispatch_async(self.logsDispatchQueue, ^{
      XCTAssertNotNil(ingestionBlock);
      if (ingestionBlock) {
        ingestionBlock([@(1) stringValue], responseMock, nil, nil);
      }

      // Then
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Get sure it has been sent.
                                 assertThat(logContainer.batchId, is(expectedBatchId));
                                 assertThat(logContainer.logs, is(@[ expectedLog ]));
                                 assertThatBool(self.sut.pendingBatchQueueFull, isFalse());
                                 assertThatBool(self.sut.enabled, isTrue());
                                 assertThatUnsignedLong(self.sut.pendingBatchIds.count, equalToUnsignedLong(0));
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(self.storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [responseMock stopMocking];
}

- (void)testEnqueuingItemsWillIncreaseCounter {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                                  priority:MSPriorityDefault
                                                                             flushInterval:5
                                                                            batchSizeLimit:10
                                                                       pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNotCheckingPendingLogsOnEnqueueFailure {

  // If
  [self initChannelEndJobExpectation];
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:5
                                                                batchSizeLimit:10
                                                           pendingBatchesLimit:3];
  self.sut.storage = self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsDefault]).andReturn(NO);
  id channelUnitMock = OCMPartialMock(self.sut);
  OCMReject([channelUnitMock checkPendingLogs]);
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [channelUnitMock stopMocking];
}

- (void)testEnqueueCriticalItem {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> mockLog = [self getValidMockLog];

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsCritical];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY flags:MSFlagsCritical]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testEnqueueNonCriticalItem {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> mockLog = [self getValidMockLog];

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsNormal];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY flags:MSFlagsNormal]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testEnqueueItemWithFlagsDefault {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> mockLog = [self getValidMockLog];

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  [self initChannelEndJobExpectation];
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:3
                                                           pendingBatchesLimit:3];
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];
  id<MSLog> mockLog = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:self.sut didCompleteEnqueueingLog:mockLog internalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        static int count = 0;
        count++;
        if (count == itemsToAdd) {
          [expectation fulfill];
        }
      });
  [self.sut addDelegate:delegateMock];

  // When
  for (int i = 0; i < itemsToAdd; ++i) {
    [self.sut enqueueItem:mockLog flags:MSFlagsCritical];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testBatchQueueLimit {

  // If
  [self initChannelEndJobExpectation];
  NSUInteger batchSizeLimit = 1;
  __block int currentBatchId = 1;
  __block NSMutableArray<NSString *> *sentBatchIds = [NSMutableArray new];
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block id responseMock = [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil];
  NSUInteger expectedMaxPendingBatched = 2;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Set up mock and stubs.
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSLogContainer *container;
    [invocation retainArguments];
    [invocation getArgument:&container atIndex:2];
    [invocation getArgument:&ingestionBlock atIndex:4];
    if (container) {
      [sentBatchIds addObject:container.batchId];
    }
  });
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionHandler loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:7];
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), [@(currentBatchId++) stringValue]);
      });
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:expectedMaxPendingBatched];

  // When
  for (NSUInteger i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
  }

  // Try to release one batch. It should trigger sending the last one.
  dispatch_async(self.logsDispatchQueue, ^{
    XCTAssertNotNil(ingestionBlock);
    if (ingestionBlock) {
      ingestionBlock([@(1) stringValue], responseMock, nil, nil);
    }
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.pendingBatchIds.count, equalToUnsignedLong(expectedMaxPendingBatched));
                                 assertThatUnsignedLong(sentBatchIds.count, equalToUnsignedLong(expectedMaxPendingBatched + 1));
                                 assertThat(sentBatchIds[0], is(@"1"));
                                 assertThat(sentBatchIds[1], is(@"2"));
                                 assertThat(sentBatchIds[2], is(@"3"));
                                 assertThatBool(self.sut.pendingBatchQueueFull, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNextBatchSentIfPendingQueueGotRoomAgain {

  // If
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation = [self expectationWithDescription:@"One log sent"];
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  NSUInteger batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
    [invocation getArgument:&lastBatchLogContainer atIndex:2];
  });
  __block id responseMock = [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil];

  // Stub the storage load for that log.
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionHandler loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:7];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), [@(currentBatchId) stringValue]);
      });

  // Configure channel.
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:1];

  // When
  [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    XCTAssertNotNil(ingestionBlock);
    if (ingestionBlock) {
      ingestionBlock([@(1) stringValue], responseMock, nil, nil);
    }

    // Then
    dispatch_async(self.logsDispatchQueue, ^{
      // Batch queue should not be full;
      assertThatBool(self.sut.pendingBatchQueueFull, isFalse());
      [oneLogSentExpectation fulfill];

      // When
      // Send another batch.
      currentBatchId++;
      [self.sut enqueueItem:[self getValidMockLog] flags:MSFlagsDefault];
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Get sure it has been sent.
                                 assertThat(lastBatchLogContainer.batchId, is([@(currentBatchId) stringValue]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [responseMock stopMocking];
}

- (void)testDontForwardLogsToIngestionOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  NSUInteger batchSizeLimit = 1;
  id mockLog = [self getValidMockLog];
  OCMReject([self.ingestionMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:10];

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerifyAll(self.ingestionMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDeleteDataOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  NSUInteger batchSizeLimit = 1;
  id mockLog = [self getValidMockLog];
  OCMStub([self.storageMock loadLogsWithGroupId:kMSTestGroupId
                                          limit:batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
  self.sut.configuration = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                      priority:MSPriorityDefault
                                                                 flushInterval:0.0
                                                                batchSizeLimit:batchSizeLimit
                                                           pendingBatchesLimit:10];

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Check that logs as been requested for
                                 // deletion and that there is no batch left.
                                 OCMVerify([self.storageMock deleteLogsWithGroupId:kMSTestGroupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDontSaveLogsWhileDisabledWithDataDeletion {

  // If
  [self initChannelEndJobExpectation];
  id mockLog = [self getValidMockLog];
  OCMReject([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:self.sut didCompleteEnqueueingLog:mockLog internalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSaveLogsAfterReEnabled {

  // If
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];
  id<MSLog> mockLog = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:self.sut didCompleteEnqueueingLog:mockLog internalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> otherMockLog = [self getValidMockLog];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  OCMStub([delegateMock channel:self.sut didCompleteEnqueueingLog:otherMockLog internalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [self.sut enqueueItem:otherMockLog flags:MSFlagsDefault];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testPauseOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.enabled, isFalse());
                                 assertThatBool(self.sut.paused, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testResumeOnEnabled {

  // If
  __block BOOL result1, result2;
  [self initChannelEndJobExpectation];
  id<MSIngestionProtocol> ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  self.sut.ingestion = ingestionMock;

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut ingestionDidResume:ingestionMock];
  });
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    result1 = self.sut.paused;
  });
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut ingestionDidPause:ingestionMock];
    dispatch_async(self.logsDispatchQueue, ^{
      [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
    });
    dispatch_async(self.logsDispatchQueue, ^{
      result2 = self.sut.paused;
    });
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(result1, isFalse());
                                 assertThatBool(result2, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDelegateAfterChannelDisabled {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  id mockLog = [self getValidMockLog];

  // When
  [self.sut addDelegate:delegateMock];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Enqueue now that the delegate is set.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut enqueueItem:mockLog flags:MSFlagsDefault];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock channel:self.sut
                                                   didPrepareLog:mockLog
                                                      internalId:OCMOCK_ANY
                                                           flags:MSFlagsDefault]);
                                 OCMVerify([delegateMock channel:self.sut didCompleteEnqueueingLog:mockLog internalId:OCMOCK_ANY]);
                                 OCMVerify([delegateMock channel:self.sut willSendLog:mockLog]);
                                 OCMVerify([delegateMock channel:self.sut didFailSendingLog:mockLog withError:anything()]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDelegateAfterChannelPaused {

  // If
  NSObject *identifyingObject = [NSObject new];
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));

  // When
  [self.sut addDelegate:delegateMock];

  // Pause now that the delegate is set.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut pauseWithIdentifyingObject:identifyingObject];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock channel:self.sut didPauseWithIdentifyingObject:identifyingObject]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDelegateAfterChannelResumed {

  // If
  NSObject *identifyingObject = [NSObject new];
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));

  // When
  [self.sut addDelegate:delegateMock];

  // Resume now that the delegate is set.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut resumeWithIdentifyingObject:identifyingObject];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock channel:self.sut didResumeWithIdentifyingObject:identifyingObject]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDeviceAndTimestampAreAddedOnEnqueuing {

  // If
  id<MSLog> mockLog = [self getValidMockLog];
  mockLog.device = nil;
  mockLog.timestamp = nil;

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];

  // Then
  XCTAssertNotNil(mockLog.device);
  XCTAssertNotNil(mockLog.timestamp);
}

- (void)testDeviceAndTimestampAreNotOverwrittenOnEnqueuing {

  // If
  id<MSLog> mockLog = [self getValidMockLog];
  MSDevice *device = mockLog.device = [MSDevice new];
  NSDate *timestamp = mockLog.timestamp = [NSDate new];

  // When
  [self.sut enqueueItem:mockLog flags:MSFlagsDefault];

  // Then
  XCTAssertEqual(mockLog.device, device);
  XCTAssertEqual(mockLog.timestamp, timestamp);
}

- (void)testEnqueuingLogDoesNotPersistFilteredLogs {

  // If
  [self initChannelEndJobExpectation];
  OCMReject([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);

  id<MSLog> log = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channelUnit:self.sut shouldFilterLog:log]).andReturn(YES);
  id delegateMock2 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock2 channelUnit:self.sut shouldFilterLog:log]).andReturn(NO);
  OCMExpect([delegateMock channel:self.sut prepareLog:log]);
  OCMExpect([delegateMock2 channel:self.sut prepareLog:log]);
  OCMExpect([delegateMock channel:self.sut didPrepareLog:log internalId:OCMOCK_ANY flags:MSFlagsDefault]);
  OCMExpect([delegateMock2 channel:self.sut didPrepareLog:log internalId:OCMOCK_ANY flags:MSFlagsDefault]);
  OCMExpect([delegateMock channel:self.sut didCompleteEnqueueingLog:log internalId:OCMOCK_ANY]);
  OCMExpect([delegateMock2 channel:self.sut didCompleteEnqueueingLog:log internalId:OCMOCK_ANY]);
  [self.sut addDelegate:delegateMock];
  [self.sut addDelegate:delegateMock2];

  // When
  dispatch_async(self.logsDispatchQueue, ^{
    // Enqueue now that the delegate is set.
    [self.sut enqueueItem:log flags:MSFlagsDefault];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(delegateMock2);
                                 OCMVerifyAll(self.storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testEnqueuingLogPersistsUnfilteredLogs {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> log = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channelUnit:self.sut shouldFilterLog:log]).andReturn(NO);
  OCMExpect([delegateMock channel:self.sut didPrepareLog:log internalId:OCMOCK_ANY flags:MSFlagsDefault]);
  OCMExpect([delegateMock channel:self.sut didCompleteEnqueueingLog:log internalId:OCMOCK_ANY]);
  [self.sut addDelegate:delegateMock];

  // When
  dispatch_async(self.logsDispatchQueue, ^{
    // Enqueue now that the delegate is set.
    [self.sut enqueueItem:log flags:MSFlagsDefault];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerifyAll(delegateMock);
                                 OCMVerify([self.storageMock saveLog:log withGroupId:OCMOCK_ANY flags:MSFlagsDefault]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDisableAndDeleteDataOnIngestionFatalError {

  // If
  [self initChannelEndJobExpectation];

  // When
  [self.sut ingestionDidReceiveFatalError:self.ingestionMock];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.enabled, isFalse());
                                 OCMVerify([self.storageMock deleteLogsWithGroupId:self.sut.configuration.groupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testPauseOnIngestionPaused {

  // If
  [self initChannelEndJobExpectation];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut ingestionDidPause:ingestionMock];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(self.sut.paused);
                                 OCMVerify([delegateMock channel:self.sut didPauseWithIdentifyingObject:ingestionMock]);
                               }];
}

- (void)testResumeOnIngestionResumed {

  // If
  [self initChannelEndJobExpectation];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut ingestionDidResume:ingestionMock];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertFalse(self.sut.paused);
                                 OCMVerify([delegateMock channel:self.sut didResumeWithIdentifyingObject:ingestionMock]);
                               }];
}

- (void)testDoesntResumeWhenNotAllPauseObjectsResumed {

  // If
  [self initChannelEndJobExpectation];
  NSObject *object1 = [NSObject new];
  NSObject *object2 = [NSObject new];
  NSObject *object3 = [NSObject new];
  [self.sut pauseWithIdentifyingObject:object1];
  [self.sut pauseWithIdentifyingObject:object2];
  [self.sut pauseWithIdentifyingObject:object3];

  // When
  [self.sut resumeWithIdentifyingObject:object1];
  [self.sut resumeWithIdentifyingObject:object3];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(self.sut.paused);
                               }];
}

- (void)testResumesWhenAllPauseObjectsResumed {

  // If
  [self initChannelEndJobExpectation];
  NSObject *object1 = [NSObject new];
  NSObject *object2 = [NSObject new];
  NSObject *object3 = [NSObject new];
  [self.sut pauseWithIdentifyingObject:object1];
  [self.sut pauseWithIdentifyingObject:object2];
  [self.sut pauseWithIdentifyingObject:object3];

  // When
  [self.sut resumeWithIdentifyingObject:object1];
  [self.sut resumeWithIdentifyingObject:object2];
  [self.sut resumeWithIdentifyingObject:object3];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertFalse(self.sut.paused);
                               }];
}

- (void)testResumeWhenOnlyPausedObjectIsDeallocated {

  // If
  __weak NSObject *weakObject = nil;
  @autoreleasepool {

// Ignore warning on weak variable usage in this scope to simulate dealloc.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
    weakObject = [NSObject new];
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
    [self.sut pauseWithIdentifyingObjectSync:weakObject];
#pragma clang diagnostic pop
  }

  // Then
  XCTAssertTrue(self.sut.paused);

  // When
  [self.sut resumeWithIdentifyingObjectSync:[NSObject new]];

  // Then
  XCTAssertFalse(self.sut.paused);
}

- (void)testResumeWithObjectThatDoesNotExistDoesNotResumeIfCurrentlyPaused {

  // If
  [self initChannelEndJobExpectation];
  NSObject *object1 = [NSObject new];
  NSObject *object2 = [NSObject new];
  [self.sut pauseWithIdentifyingObject:object1];

  // When
  [self.sut resumeWithIdentifyingObject:object2];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(self.sut.paused);
                               }];
}

- (void)testResumeWithObjectThatDoesNotExistDoesNotPauseIfPreviouslyResumed {

  // When
  [self.sut resumeWithIdentifyingObjectSync:[NSObject new]];

  // Then
  XCTAssertFalse(self.sut.paused);
}

- (void)testResumeTwiceInARowResumesWhenPaused {

  // If
  NSObject *object = [NSObject new];
  [self.sut pauseWithIdentifyingObjectSync:object];

  // When
  [self.sut resumeWithIdentifyingObjectSync:object];
  [self.sut resumeWithIdentifyingObjectSync:object];

  // Then
  XCTAssertFalse(self.sut.paused);
}

- (void)testResumeOnceResumesWhenPausedTwiceWithSingleObject {

  // If
  NSObject *object = [NSObject new];
  [self.sut pauseWithIdentifyingObjectSync:object];
  [self.sut pauseWithIdentifyingObjectSync:object];

  // When
  [self.sut resumeWithIdentifyingObjectSync:object];

  // Then
  XCTAssertFalse(self.sut.paused);
}

- (void)testPausedTargetKeysNotAlteredWhenChannelUnitPaused {

  // If
  [self initChannelEndJobExpectation];
  NSObject *object = [NSObject new];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  [self.sut pauseSendingLogsWithToken:token];

  // When
  [self.sut pauseWithIdentifyingObjectSync:object];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(1));
                                 XCTAssertTrue([self.sut.pausedTargetKeys containsObject:targetKey]);
                               }];
}

- (void)testPausedTargetKeysNotAlteredWhenChannelUnitResumed {

  // If
  [self initChannelEndJobExpectation];
  NSObject *object = [NSObject new];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  [self.sut pauseSendingLogsWithToken:token];
  [self.sut pauseWithIdentifyingObject:object];

  // When
  [self.sut resumeWithIdentifyingObject:object];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(1));
                                 XCTAssertTrue([self.sut.pausedTargetKeys containsObject:targetKey]);
                               }];
}

- (void)testNoLogsRetrievedFromStorageWhenTargetKeyIsPaused {

  // If
  [self initChannelEndJobExpectation];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  __block NSArray *excludedKeys;
  OCMStub([self.storageMock loadLogsWithGroupId:self.sut.configuration.groupId
                                          limit:self.sut.configuration.batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&excludedKeys atIndex:4];
      });
  [self.sut pauseSendingLogsWithToken:token];

  // When
  dispatch_async(self.logsDispatchQueue, ^{
    [self.sut flushQueue];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(excludedKeys.count, equalToUnsignedLong(1));
                                 XCTAssertTrue([excludedKeys containsObject:targetKey]);
                               }];
}

- (void)testFlushQueueIteratesThroughArrayRecursively {

  // If
  [self initChannelEndJobExpectation];
  NSArray<NSNumber *> *datesValues = @[ @1, @60, @120, @180, @240 ];
  NSMutableArray<NSNumber *> *logsCount = [@[ @0, @199, @0, @5 ] mutableCopy];

  // Fill the values.
  NSMutableArray<NSDate *> *dates = [NSMutableArray<NSDate *> new];
  for (NSUInteger i = 0; i < datesValues.count; i++) {
    [dates addObject:[NSDate dateWithTimeIntervalSince1970:[datesValues[i] doubleValue]]];
  }
  NSMutableArray<MSAuthTokenValidityInfo *> *tokenValidityArray = [NSMutableArray<MSAuthTokenValidityInfo *> new];
  for (NSUInteger i = 0; i < dates.count - 1; i++) {
    NSString *token = [NSString stringWithFormat:@"token%tu", i];
    [tokenValidityArray addObject:[[MSAuthTokenValidityInfo alloc] initWithAuthToken:token startTime:dates[i] endTime:dates[i+1]]];
  }

  // Configure ingestion mock.
  NSMutableDictionary<NSString *, MSSendAsyncCompletionHandler> *sendingBatches = [NSMutableDictionary new];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY authToken:OCMOCK_ANY completionHandler:OCMOCK_ANY])
  .andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];
    MSLogContainer *logContainer;
    [invocation getArgument:&logContainer atIndex:2];
    MSSendAsyncCompletionHandler completionHandler;
    [invocation getArgument:&completionHandler atIndex:4];
    sendingBatches[logContainer.batchId] = completionHandler;
  });

  // Configure storage mock.
  __block NSUInteger batchCount = 0;
  OCMStub([self.storageMock countLogsBeforeDate:dates[1]]).andReturn(0);
  OCMStub([self.storageMock loadLogsWithGroupId:self.sut.configuration.groupId
                                          limit:self.sut.configuration.batchSizeLimit
                             excludedTargetKeys:OCMOCK_ANY
                                      afterDate:OCMOCK_ANY
                                     beforeDate:OCMOCK_ANY
                              completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        // TODO (improvement): in-memory storage mock implementation would be nice here.

        // Read the arguments.
        NSUInteger limit;
        [invocation getArgument:&limit atIndex:3];
        NSDate *dateAfter;
        [invocation getArgument:&dateAfter atIndex:5];
        NSDate *dateBefore;
        [invocation getArgument:&dateBefore atIndex:6];
        MSLoadDataCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:7];

        // Simulate loading.
        BOOL availableBatchFromStorage = NO;
        for (NSUInteger i = 0; i < tokenValidityArray.count; i++) {
          if ([dateAfter isEqualToDate:dates[i]] && [dateBefore isEqualToDate:dates[i + 1]]) {
            NSUInteger count = [logsCount[i] unsignedIntegerValue];
            if (count > limit) {
              availableBatchFromStorage = YES;
              logsCount[i] = @(count - limit);
            }
            NSString *batchId = [@"batch" stringByAppendingString:[@(batchCount++) stringValue]];
            completionHandler([self getValidMockLogArrayForDate:dates[i] andCount:count], batchId);
            break;
          }
        }
        [invocation setReturnValue:&availableBatchFromStorage];
      });

  // When
  OCMReject([self.authTokenContextMock removeAuthToken:isNot(equalTo(@"token0"))]);
  [self.sut flushQueueForTokenArray:tokenValidityArray withTokenIndex:0];

  // Finalize some of the ingestion calls.
  id response = OCMClassMock([NSHTTPURLResponse class]);
  OCMStub([response statusCode]).andReturn(MSHTTPCodesNo200OK);
  sendingBatches[@"batch1"](@"batch1", response, nil, nil);
  sendingBatches[@"batch2"](@"batch2", response, nil, nil);

  // Then
  OCMVerify([self.authTokenContextMock removeAuthToken:@"token0"]);
  OCMVerify([self.ingestionMock sendAsync:hasProperty(@"batchId", @"batch1") authToken:@"token1" completionHandler:OCMOCK_ANY]);
  OCMVerify([self.ingestionMock sendAsync:hasProperty(@"batchId", @"batch2") authToken:@"token1" completionHandler:OCMOCK_ANY]);
  OCMVerify([self.ingestionMock sendAsync:hasProperty(@"batchId", @"batch3") authToken:@"token1" completionHandler:OCMOCK_ANY]);
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([self.ingestionMock sendAsync:hasProperty(@"batchId", @"batch4") authToken:@"token1" completionHandler:OCMOCK_ANY]);
                                 OCMVerify([self.ingestionMock sendAsync:hasProperty(@"batchId", @"batch6") authToken:@"token3" completionHandler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.authTokenContextMock);
                               }];
  [response stopMocking];
}

- (void)testLogsStoredWhenTargetKeyIsPaused {

  // If
  [self initChannelEndJobExpectation];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  [self.sut pauseSendingLogsWithToken:token];
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  [log addTransmissionTargetToken:token];
  log.ver = @"3.0";
  log.name = @"test";
  log.iKey = targetKey;

  // When
  [self.sut enqueueItem:log flags:MSFlagsDefault];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([self.storageMock saveLog:log withGroupId:self.sut.configuration.groupId flags:MSFlagsDefault]);
                               }];
}

- (void)testSendingPendingLogsOnResume {

  // If
  [self initChannelEndJobExpectation];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  id channelUnitMock = OCMPartialMock(self.sut);
  [self.sut pauseSendingLogsWithToken:token];
  OCMStub([self.storageMock countLogs]).andReturn(60);

  // When
  [self.sut resumeSendingLogsWithToken:token];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 OCMVerify([self.storageMock countLogs]);
                                 OCMVerify([channelUnitMock checkPendingLogs]);

                                 // The count should be 0 since the logs were sent and not in pending state anymore.
                                 XCTAssertEqual(self.sut.itemsCount, 0);
                               }];
  [channelUnitMock stopMocking];
}

- (void)testTargetKeyRemainsPausedWhenPausedASecondTime {

  // If
  [self initChannelEndJobExpectation];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  [self.sut pauseSendingLogsWithToken:token];

  // When
  [self.sut pauseSendingLogsWithToken:token];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(1));
                                 XCTAssertTrue([self.sut.pausedTargetKeys containsObject:targetKey]);
                               }];
}

- (void)testTargetKeyRemainsResumedWhenResumedASecondTime {

  // If
  [self initChannelEndJobExpectation];
  NSString *targetKey = @"targetKey";
  NSString *token = [NSString stringWithFormat:@"%@-secret", targetKey];
  [self.sut pauseSendingLogsWithToken:token];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(1));
                                 XCTAssertTrue([self.sut.pausedTargetKeys containsObject:targetKey]);
                               }];

  // If
  [self initChannelEndJobExpectation];

  // When
  [self.sut resumeSendingLogsWithToken:token];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(0));
                               }];

  // If
  [self initChannelEndJobExpectation];

  // When
  [self.sut resumeSendingLogsWithToken:token];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 assertThatUnsignedLong(self.sut.pausedTargetKeys.count, equalToUnsignedLong(0));
                               }];
}

- (void)testEnqueueItemDoesNotSetUserIdWhenItAlreadyHasOne {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> enqueuedLog = [self getValidMockLog];
  NSString *expectedUserId = @"Fake-UserId";
  __block NSString *actualUserId;
  id userIdContextMock = OCMClassMock([MSUserIdContext class]);
  OCMStub([userIdContextMock sharedInstance]).andReturn(userIdContextMock);
  OCMStub([userIdContextMock userId]).andReturn(@"SomethingElse");
  self.sut.storage = self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY flags:MSFlagsNormal])
      .andDo(^(NSInvocation *invocation) {
        MSAbstractLog *log;
        [invocation getArgument:&log atIndex:2];
        actualUserId = log.userId;
        [self enqueueChannelEndJobExpectation];
      })
      .andReturn(YES);

  // When
  enqueuedLog.userId = expectedUserId;
  [self.sut enqueueItem:enqueuedLog flags:MSFlagsDefault];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(actualUserId, expectedUserId);
                               }];
  [userIdContextMock stopMocking];
}

#pragma mark - Helper

- (void)initChannelEndJobExpectation {
  self.channelEndJobExpectation = [self expectationWithDescription:@"Channel job should be finished"];
}

- (void)enqueueChannelEndJobExpectation {

  // Enqueue end job expectation on channel's queue to detect when channel
  // finished processing.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.channelEndJobExpectation fulfill];
  });
}

- (NSArray<id<MSLog>> *)getValidMockLogArrayForDate:(NSDate *)date andCount:(NSUInteger)count {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
  for (NSUInteger i = 0; i < count; i++) {
    [logs addObject:[self getValidMockLogWithDate:[date dateByAddingTimeInterval:i]]];
  }
  return logs;
}

- (id)getValidMockLog {
  id mockLog = OCMPartialMock([MSAbstractLog new]);
  OCMStub([mockLog isValid]).andReturn(YES);
  return mockLog;
}

- (id)getValidMockLogWithDate:(NSDate *)date {
  id<MSLog> mockLog = OCMPartialMock([MSAbstractLog new]);
  OCMStub([mockLog timestamp]).andReturn(date);
  OCMStub([mockLog isValid]).andReturn(YES);
  return mockLog;
}

@end
