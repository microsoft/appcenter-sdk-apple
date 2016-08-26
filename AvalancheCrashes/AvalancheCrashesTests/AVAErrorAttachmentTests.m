#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAErrorAttachment.h"
#import "AVABinaryAttachment.h"

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
  AVABinaryAttachment *binaryAttachment = [[AVABinaryAttachment alloc] initWithFilename:fileName attachmentData: data contentType:contentType];
  sut.attachmentFile = binaryAttachment;
  
  assertThat(sut, notNilValue());
  assertThat(sut.textAttachment, equalTo(textAttachment));
  assertThat(sut.attachmentFile, equalTo(binaryAttachment));
}

@end