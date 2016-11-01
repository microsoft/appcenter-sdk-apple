#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMAbstractLog.h"
#import "SNMChannelConfiguration.h"
#import "SNMChannelDefault.h"
#import "SNMLogManagerDefault.h"

@interface SNMLogManagerDefaultTests : XCTestCase

@end

@implementation SNMLogManagerDefaultTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));

  // When
  SNMLogManagerDefault *sut = [[SNMLogManagerDefault alloc] initWithSender:senderMock storage:storageMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.logsDispatchQueue, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
}

- (void)testProcessingWithNewPriorityWillCreateNewChannel {

  // If
  SNMPriority priority = SNMPriorityDefault;
  SNMLogManagerDefault *sut = [[SNMLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(SNMSender))
                                                                   storage:OCMProtocolMock(@protocol(SNMStorage))];
  SNMAbstractLog *log = [SNMAbstractLog new];
  assertThat(sut.channels, isEmpty());

  // When
  [sut processLog:log withPriority:priority];

  // Then
  assertThat(sut.channels[@(priority)], notNilValue());
}

@end
