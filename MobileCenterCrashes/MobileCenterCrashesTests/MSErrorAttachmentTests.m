@import Foundation;
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
@import XCTest;

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

@end
