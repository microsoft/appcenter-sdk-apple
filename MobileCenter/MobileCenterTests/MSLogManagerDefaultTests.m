#import "MSAbstractLogInternal.h"
#import "MSChannelConfiguration.h"
#import "MSChannelDefault.h"
#import "MSHttpSenderPrivate.h"
#import "MSLogManagerDefault.h"
#import "MSLogManagerDefaultPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

@interface MSLogManagerDefaultTests : XCTestCase

@end

@implementation MSLogManagerDefaultTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));

  // When
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.logsDispatchQueue, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
#if !TARGET_OS_OSX
  assertThatInt(sut.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));
#endif
}

- (void)testInitNewChannel {

  // If
  NSString *groupId = @"MobileCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];

  // Then
  assertThat(sut.channels, isEmpty());

  // When
  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupId:groupId
                                                                           priority:priority
                                                                      flushInterval:flushInterval
                                                                     batchSizeLimit:batchSizeLimit
                                                                pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  MSChannelDefault *channel = sut.channels[groupId];
  assertThat(channel, notNilValue());
  XCTAssertTrue(channel.configuration.priority == priority);
  assertThatFloat(channel.configuration.flushInterval, equalToFloat(flushInterval));
  assertThatUnsignedLong(channel.configuration.batchSizeLimit, equalToUnsignedLong(batchSizeLimit));
  assertThatUnsignedLong(channel.configuration.pendingBatchesLimit, equalToUnsignedLong(pendingBatchesLimit));
}

- (void)testProcessingLogWillTriggerOnProcessingCall {

  // If
  MSPriority priority = MSPriorityDefault;
  NSString *groupId = @"MobileCenter";
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
  id mockDelegate = OCMProtocolMock(@protocol(MSLogManagerDelegate));
  [sut addDelegate:mockDelegate];
  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupId:groupId
                                                                           priority:priority
                                                                      flushInterval:1.0
                                                                     batchSizeLimit:10
                                                                pendingBatchesLimit:3]];

  MSAbstractLog *log = [MSAbstractLog new];

  // When
  [sut processLog:log forGroupId:groupId];

  // Then
  OCMVerify([mockDelegate onPreparedLog:log withInternalId:OCMOCK_ANY]);
  OCMVerify([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
}

- (void)testDelegatesConcurrentAccess {

  // If
  NSString *groupId = @"MobileCenter";
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
  MSAbstractLog *log = [MSAbstractLog new];
  for (int j = 0; j < 10; j++) {
    id mockDelegate = OCMProtocolMock(@protocol(MSLogManagerDelegate));
    [sut addDelegate:mockDelegate];
  }

  // When
  void (^block)() = ^{
    for (int i = 0; i < 10; i++) {
      [sut processLog:log forGroupId:groupId];
    }
    for (int i = 0; i < 100; i++) {
      [sut addDelegate:OCMProtocolMock(@protocol(MSLogManagerDelegate))];
    }
  };

  // Then
  XCTAssertNoThrow(block());
}

#if !TARGET_OS_OSX

- (void)testAppBackgroundedAndChannelsWillFinishFlushing {

  /*
   * The app is going to the background, logmanager should request to be notified by channels when they stopped flushing.
   * Logmanager should make sure all channels stopped flushing before cancelling the background task.
   * Then, disable sender so it can't react to network events in background in case other tasks from the app are still
   * running.
   */

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([utilityMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY]).andReturn(UIBackgroundTaskInvalid + 1);
  __block BOOL isSenderDisabled = NO;
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock setEnabled:NO andDeleteDataOnDisabled:NO])
      .andDo(^(__attribute__((unused)) NSInvocation *invocation) {
        isSenderDisabled = YES;
      });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Init 2 channels.
  __block MSStopFlushingCompletionBlock completionBlockChannel1;
  __block MSStopFlushingCompletionBlock completionBlockChannel2;
  MSChannelDefault *channel1 = OCMClassMock([MSChannelDefault class]);
  MSChannelDefault *channel2 = OCMClassMock([MSChannelDefault class]);
  OCMStub([channel1 stopFlushingWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];

    // Remember the completion block.
    [invocation getArgument:&completionBlockChannel1 atIndex:2];
  });
  OCMStub([channel2 stopFlushingWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];

    // Remember the completion block.
    [invocation getArgument:&completionBlockChannel2 atIndex:2];
  });

  // Add channels.
  sut.channels[@"channel1"] = channel1;
  sut.channels[@"channel2"] = channel2;

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:sut];

  // Then
  assertThatInt(sut.flushedChannelsCount, equalToInt(0));
  completionBlockChannel1();
  assertThatInt(sut.flushedChannelsCount, equalToInt(1));
  assertThatBool(isSenderDisabled, isFalse());
  assertThatInt(sut.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid + 1));
  completionBlockChannel2();
  assertThatInt(sut.flushedChannelsCount, equalToInt(0));
  assertThatBool(isSenderDisabled, isTrue());
  assertThatInt(sut.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));

  // Explicitly unmock MSUtility since it's stubbing a class method.
  [utilityMock stopMocking];
}

- (void)testAppBackgroundedAndChannelsWontFinishFlushing {

  /*
   * The app is going to the background, logmanager should request to be notified by channels when they stopped flushing.
   * Channel won't fininsh flushing before background will finish.
   * In this case, logmanager must disable sender.
   */

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  __block id expirationBlock = nil;
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([utilityMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    long long bgNumber = UIBackgroundTaskInvalid + 1;
    [invocation retainArguments];
    [invocation getArgument:&expirationBlock atIndex:2];
    [invocation setReturnValue:&bgNumber];
  });
  __block BOOL isSenderDisabled = NO;
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock setEnabled:NO andDeleteDataOnDisabled:NO])
      .andDo(^(__attribute__((unused)) NSInvocation *invocation) {
        isSenderDisabled = YES;
      });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Init 2 channels.
  __block MSStopFlushingCompletionBlock completionBlockChannel1;
  __block MSStopFlushingCompletionBlock completionBlockChannel2;
  id channel1 = OCMClassMock([MSChannelDefault class]);
  id channel2 = OCMClassMock([MSChannelDefault class]);
  OCMStub([channel1 stopFlushingWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];

    // Remember the completion block.
    [invocation getArgument:&completionBlockChannel1 atIndex:2];
  });
  OCMStub([channel2 stopFlushingWithCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];

    // Remember the completion block.
    [invocation getArgument:&completionBlockChannel2 atIndex:2];
  });

  // Add channels.
  sut.channels[@"channel1"] = channel1;
  sut.channels[@"channel2"] = channel2;

  // Simulate background.
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:sut];

  // When
  ((void (^)())expirationBlock)();

  // Then
  assertThatInt(sut.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid + 1));
  assertThatInt(sut.flushedChannelsCount, equalToInt(0));
  assertThatBool(isSenderDisabled, isTrue());
  completionBlockChannel1();
  completionBlockChannel2();
  assertThatInt(sut.flushedChannelsCount, equalToInt(0));

  // Explicitly unmock MSUtility since it's stubbing a class method.
  [utilityMock stopMocking];
}

- (void)testAppBackgroundedThenForegroundedAndChannelsWontFinishFlushing {

  /*
   * The app is going to the background, logmanager should request to be notified by channels when they stopped flushing.
   * Channel won't fininsh flushing before background will finish.
   * In this case, logmanager must disable sender.
   */

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  __block id expirationBlock = nil;
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([utilityMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    long long bgNumber = UIBackgroundTaskInvalid + 1;
    [invocation retainArguments];
    [invocation getArgument:&expirationBlock atIndex:2];
    [invocation setReturnValue:&bgNumber];
  });
  __block BOOL isSenderDisabled = YES;
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock setEnabled:YES andDeleteDataOnDisabled:NO])
      .andDo(^(__attribute__((unused)) NSInvocation *invocation) {
        isSenderDisabled = NO;
      });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Init 2 channels.
  id channel1 = OCMClassMock([MSChannelDefault class]);
  id channel2 = OCMClassMock([MSChannelDefault class]);
  OCMExpect([channel1 cancelStopFlushing]);
  OCMExpect([channel2 cancelStopFlushing]);
  OCMStub([channel1 stopFlushingWithCompletion:OCMOCK_ANY]);
  OCMStub([channel2 stopFlushingWithCompletion:OCMOCK_ANY]);

  // Add channels.
  sut.channels[@"channel1"] = channel1;
  sut.channels[@"channel2"] = channel2;

  // Simulate background.
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:sut];

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:sut];

  // Then
  assertThatInt(sut.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));
  assertThatInt(sut.flushedChannelsCount, equalToInt(0));
  assertThatBool(isSenderDisabled, isFalse());
  OCMVerifyAll(channel1);
  OCMVerifyAll(channel2);

  // Explicitly unmock MSUtility since it's stubbing a class method.
  [utilityMock stopMocking];
}

#endif

@end
