#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSErrorBinaryAttachment.h"

@interface MSErrorBinaryAttachmentTests : XCTestCase

@end


@implementation MSErrorBinaryAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  
  MSErrorBinaryAttachment *sut = [[MSErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];
  assertThat(sut, notNilValue());
  assertThat(sut.fileName, equalTo(fileName));
  assertThat(sut.data, equalTo(data));
  assertThat(sut.contentType, equalTo(contentType));
}


@end
