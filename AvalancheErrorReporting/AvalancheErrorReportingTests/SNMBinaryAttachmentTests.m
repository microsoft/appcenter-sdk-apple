#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "SNMErrorBinaryAttachment.h"

@interface SNMErrorBinaryAttachmentTests : XCTestCase

@end


@implementation SNMErrorBinaryAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  
  SNMErrorBinaryAttachment *sut = [[SNMErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  assertThat(sut, notNilValue());
  assertThat(sut.fileName, equalTo(fileName));
  assertThat(sut.data, equalTo(data));
  assertThat(sut.contentType, equalTo(contentType));
}


@end
