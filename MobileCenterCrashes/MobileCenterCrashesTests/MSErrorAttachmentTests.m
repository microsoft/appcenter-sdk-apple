#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSErrorAttachment.h"
#import "MSErrorBinaryAttachment.h"

@interface MSErrorAttachmentTests : XCTestCase

@end

@implementation MSErrorAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  MSErrorAttachment *sut = [MSErrorAttachment new];
  NSString *textAttachment = @"A text attachment";
  sut.textAttachment = textAttachment;
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  MSErrorBinaryAttachment *binaryAttachment = [[MSErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  sut.binaryAttachment = binaryAttachment;
  
  assertThat(sut, notNilValue());
  assertThat(sut.textAttachment, equalTo(textAttachment));
  assertThat(sut.binaryAttachment, equalTo(binaryAttachment));
}

- (void)testEquals {
  MSErrorAttachment *sut = [MSErrorAttachment new];
  NSString *textAttachment = @"A text attachment";
  sut.textAttachment = textAttachment;
  
  MSErrorAttachment *other = [MSErrorAttachment attachmentWithText:@"A text attachment"];
  assertThat(sut, equalTo(other));
  
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  MSErrorBinaryAttachment *binaryAttachment = [[MSErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  sut.binaryAttachment = binaryAttachment;
  
  other = [MSErrorAttachment attachmentWithText:@"A text attachment" andBinaryData:data filename:fileName mimeType:contentType];
  assertThat(sut, equalTo(other));
  
  sut.textAttachment = nil;
  other = [MSErrorAttachment attachmentWithBinaryData:data filename:fileName mimeType:contentType];
  assertThat(sut, equalTo(other));
}

@end
