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
  id senderMock = OCMProtocolMock(@protocol(AVASender));
  id storageMock = OCMProtocolMock(@protocol(AVAStorage));

  // When
  AVALogManagerDefault *sut = [[AVALogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.dataItemsOperations, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
}

- (void)testProcessingWithNewPriorityWillCreateNewChannel {

  // If
  AVAPriority priority = AVAPriorityDefault;
  AVALogManagerDefault *sut = [[AVALogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(AVASender))
                                                                   storage:OCMProtocolMock(@protocol(AVAStorage))];
  AVAAbstractLog *log = [AVAAbstractLog new];
  assertThat(sut.channels, isEmpty());

  // When
  [sut processLog:log withPriority:priority];

  // Then
  assertThat(sut.channels[@(priority)], notNilValue());
}

@end
