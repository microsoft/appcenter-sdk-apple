#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSErrorBinaryAttachment.h"
#import "MSErrorBinaryAttachmentPrivate.h"

@interface MSErrorBinaryAttachmentTests : XCTestCase

@end


@implementation MSErrorBinaryAttachmentTests

#pragma mark - Helper

- (MSErrorBinaryAttachment *)attachment {
  NSString *fileName = @"binaryAttachmentFileName";
  NSData *data = [[NSData alloc] initWithContentsOfFile:@"Binary"];
  NSString *contentType = @"image/jpeg";
  MSErrorBinaryAttachment *attachment = [[MSErrorBinaryAttachment alloc] initWithFileName:fileName attachmentData:data contentType:contentType];

  assertThat(attachment, notNilValue());
  assertThat(attachment.fileName, equalTo(fileName));
  assertThat(attachment.data, equalTo(data));
  assertThat(attachment.contentType, equalTo(contentType));
  return attachment;
}

#pragma mark - Tests

- (void)testSerialilzingBinaryToDictionaryWorks {

  // If
  MSErrorBinaryAttachment *sut = [self attachment];

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"file_name"], equalTo(sut.fileName));
  assertThat(actual[@"data"], equalTo(sut.data));
  assertThat(actual[@"content_type"], equalTo(sut.contentType));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  // If
  MSErrorBinaryAttachment *sut = [self attachment];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSErrorBinaryAttachment class]));

  MSErrorBinaryAttachment *actualAttachment = actual;
  assertThat(actualAttachment, equalTo(sut));
  assertThat(actualAttachment.fileName, equalTo(sut.fileName));
  assertThat(actualAttachment.data, equalTo(sut.data));
  assertThat(actualAttachment.contentType, equalTo(sut.contentType));
}

@end
