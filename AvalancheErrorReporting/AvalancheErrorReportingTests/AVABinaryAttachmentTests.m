#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "AVAErrorBinaryAttachment.h"

@interface AVAErrorBinaryAttachmentTests : XCTestCase

@end


@implementation AVAErrorBinaryAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  
  AVAErrorBinaryAttachment *sut = [[AVAErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  assertThat(sut, notNilValue());
  assertThat(sut.fileName, equalTo(fileName));
  assertThat(sut.data, equalTo(data));
  assertThat(sut.contentType, equalTo(contentType));
}


@end
