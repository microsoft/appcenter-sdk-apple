#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAErrorAttachment.h"
#import "AVAErrorBinaryAttachment.h"

@interface AVAErrorAttachmentTests : XCTestCase

@end

@implementation AVAErrorAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  AVAErrorAttachment *sut = [AVAErrorAttachment new];
  NSString *textAttachment = @"A text attachment";
  sut.textAttachment = textAttachment;
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  AVAErrorBinaryAttachment *binaryAttachment = [[AVAErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  sut.binaryAttachment = binaryAttachment;
  
  assertThat(sut, notNilValue());
  assertThat(sut.textAttachment, equalTo(textAttachment));
  assertThat(sut.binaryAttachment, equalTo(binaryAttachment));
}

@end
