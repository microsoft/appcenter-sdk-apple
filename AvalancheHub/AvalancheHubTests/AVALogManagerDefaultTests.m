#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAbstractLog.h"
#import "AVAChannelConfiguration.h"
#import "AVAChannelDefault.h"
#import "AVALogManagerDefault.h"

@interface AVALogManagerDefaultTests : XCTestCase

@end

@implementation AVALogManagerDefaultTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id channelMock = OCMProtocolMock(@protocol(AVAChannel));
  NSArray<AVAChannel> *channels =
      [NSArray<AVAChannel> arrayWithObject:channelMock];

  // When
  AVALogManagerDefault *sut =
      [[AVALogManagerDefault alloc] initWithChannels:channels];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.dataItemsOperations, notNilValue());
  assertThat(sut.channels, hasValue(channelMock));
  assertThatInteger(sut.channels.allKeys.count, equalToInteger(1));
}

- (void)testProcessingLogWillForwardItToRightChannel {

  // If
  AVAPriority priority = AVAPriorityDefault;
  AVAChannelDefault *channel = [[AVAChannelDefault alloc]
      initWithSender:OCMProtocolMock(@protocol(AVASender))
             storage:OCMProtocolMock(@protocol(AVAStorage))
            priority:priority];
  id channelMock = OCMPartialMock(channel);
  NSArray<AVAChannel> *channels =
      [NSArray<AVAChannel> arrayWithObject:channelMock];
  AVALogManagerDefault *sut =
      [[AVALogManagerDefault alloc] initWithChannels:channels];
  AVAAbstractLog *log = [AVAAbstractLog new];

  // When
  [sut processLog:log withPriority:priority];

  // Then
  dispatch_sync(sut.dataItemsOperations, ^{
    OCMVerify([channelMock enqueueItem:log]);
  });
}

- (void)testProcessingLogWontBeForwardedIfNoChannelForPriorityExists {
  
  // If
  AVAPriority priority = AVAPriorityDefault;
  AVAChannelDefault *channel = [[AVAChannelDefault alloc]
                                initWithSender:OCMProtocolMock(@protocol(AVASender))
                                storage:OCMProtocolMock(@protocol(AVAStorage))
                                priority:priority];
  id channelMock = OCMPartialMock(channel);
  NSArray<AVAChannel> *channels =
  [NSArray<AVAChannel> arrayWithObject:channelMock];
  AVALogManagerDefault *sut =
  [[AVALogManagerDefault alloc] initWithChannels:channels];
  AVAAbstractLog *log = [AVAAbstractLog new];
  
  // When
  [sut processLog:log withPriority:AVAPriorityHigh];
  
  // Then
  dispatch_sync(sut.dataItemsOperations, ^{
    OCMVerify([[channelMock reject] enqueueItem:log]);
  });
}

@end
