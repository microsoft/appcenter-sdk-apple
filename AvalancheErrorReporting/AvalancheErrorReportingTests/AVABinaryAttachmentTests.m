#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "AVABinaryAttachment.h"

@interface AVABinaryAttachmentTests : XCTestCase

@end


@implementation AVABinaryAttachmentTests

#pragma mark - Tests

- (void)testInitializationWorks {
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [NSData new];
  NSString *contentType = @"image/jpeg";
  
  AVABinaryAttachment *sut = [[AVABinaryAttachment alloc] initWithFilename:fileName attachmentData: data contentType:contentType];
  assertThat(sut, notNilValue());
  assertThat(sut.filename, equalTo(fileName));
  assertThat(sut.data, equalTo(data));
  assertThat(sut.contentType, equalTo(contentType));
}


@end