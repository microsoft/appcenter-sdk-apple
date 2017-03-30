#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLog.h"
#import "MSChannelConfiguration.h"
#import "MSChannelDefault.h"
#import "MSLogManagerDefault.h"
#import "MSLogManagerDefaultPrivate.h"

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
}

- (void)testInitNewChannel {

  // If
  NSString *groupID = @"MobileCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];

  // Then
  assertThat(sut.channels, isEmpty());

  // When
  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupID:groupID
                                                                           priority:priority
                                                                      flushInterval:flushInterval
                                                                     batchSizeLimit:batchSizeLimit
                                                                pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  MSChannelDefault *channel = sut.channels[groupID];
  assertThat(channel, notNilValue());
  XCTAssertTrue(channel.configuration.priority == priority);
  assertThatFloat(channel.configuration.flushInterval, equalToFloat(flushInterval));
  assertThatUnsignedInt(channel.configuration.batchSizeLimit, equalToUnsignedInteger(batchSizeLimit));
  assertThatUnsignedInt(channel.configuration.pendingBatchesLimit, equalToUnsignedInteger(pendingBatchesLimit));
}

- (void)testProcessingLogWillTriggerOnProcessingCall {

  // If
  MSPriority priority = MSPriorityDefault;
  NSString *groupID = @"MobileCenter";
  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
  id mockDelegate = OCMProtocolMock(@protocol(MSLogManagerDelegate));
  [sut addDelegate:mockDelegate];
  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupID:groupID
                                                                           priority:priority
                                                                      flushInterval:1.0
                                                                     batchSizeLimit:10
                                                                pendingBatchesLimit:3]];

  MSAbstractLog *log = [MSAbstractLog new];

  // When
  [sut processLog:log forGroupID:groupID];

  // Then
  OCMVerify([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY andPriority:priority]);
}

@end
