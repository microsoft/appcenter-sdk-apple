#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMErrorAttachment.h"
#import "SNMErrorBinaryAttachment.h"

@interface SNMErrorAttachmentTests : XCTestCase

@end

@implementation SNMErrorAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  SNMErrorAttachment *sut = [SNMErrorAttachment new];
  NSString *textAttachment = @"A text attachment";
  sut.textAttachment = textAttachment;
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  SNMErrorBinaryAttachment *binaryAttachment = [[SNMErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  sut.binaryAttachment = binaryAttachment;
  
  assertThat(sut, notNilValue());
  assertThat(sut.textAttachment, equalTo(textAttachment));
  assertThat(sut.binaryAttachment, equalTo(binaryAttachment));
}

@end
