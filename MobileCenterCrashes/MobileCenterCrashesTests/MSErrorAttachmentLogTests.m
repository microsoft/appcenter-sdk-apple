#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSDevice.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLog+Utility.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSUtility.h"

@interface MSErrorAttachmentLogTests : XCTestCase

@property(nonatomic) MSErrorAttachmentLog *sut;

@end

@implementation MSErrorAttachmentLogTests

#pragma mark - Tests

- (void)setUp {
  [super setUp];
  NSString *expectedText = @"Please attach me, I am a nice text.";
  NSString *expectedFilename = @"niceFile.txt";
  self.sut = [[MSErrorAttachmentLog alloc] initWithFilename:expectedFilename attachmentText:expectedText];
}

- (void)testInitializationWorks {

  // When
  self.sut = [MSErrorAttachmentLog new];

  // Then
  assertThat(self.sut.attachmentId, notNilValue());

  // When
  NSString *expectedText = @"Please attach me, I am a nice text.";
  NSString *expectedFilename = @"niceFile.txt";
  self.sut = [[MSErrorAttachmentLog alloc] initWithFilename:expectedFilename attachmentText:expectedText];

  // Then
  assertThat(self.sut.attachmentId, notNilValue());
  assertThat(self.sut.filename, is(expectedFilename));
  assertThat(self.sut.data, is([expectedText dataUsingEncoding:NSUTF8StringEncoding]));

  // When
  NSData *expectedData = [@"<file><request>Please attach me</request><reason>I am a nice data.</reason></file>"
      dataUsingEncoding:NSUTF8StringEncoding];
  expectedFilename = @"niceFile.xml";
  self.sut = [[MSErrorAttachmentLog alloc] initWithFilename:expectedFilename
                                           attachmentBinary:expectedData];

  // Then
  assertThat(self.sut.attachmentId, notNilValue());
  assertThat(self.sut.filename, is(expectedFilename));
  assertThat(self.sut.data, is(expectedData));

  // When
  self.sut = [[MSErrorAttachmentLog alloc] initWithFilename:nil attachmentBinary:expectedData];

  // Then
  assertThat(self.sut.attachmentId, notNilValue());
  assertThat(self.sut.filename, nilValue());
  assertThat(self.sut.data, is(expectedData));
  
  // When
  self.sut = [[MSErrorAttachmentLog alloc] initWithFilename:@"" attachmentBinary:expectedData];
  
  // Then
  assertThat(self.sut.attachmentId, notNilValue());
  assertThat(self.sut.filename, notNilValue());
  assertThat(self.sut.data, is(expectedData));
}

- (void)testEquals {

  // When
  NSString *text = @"Please attach me, I am a nice text.";
  NSString *filename = @"niceFile.txt";
  self.sut = [MSErrorAttachmentLog attachmentWithText:text filename:filename];
  MSErrorAttachmentLog *other1 =
      [MSErrorAttachmentLog attachmentWithText:@"Please attach me, I am a nice text." filename:@"niceFile.txt"];
  other1.attachmentId = self.sut.attachmentId;

  // Then
  assertThat(self.sut, is(other1));

  // When
  NSData *data = [@"<file><request>Please attach me</request><reason>I am a nice data.</reason></file>"
      dataUsingEncoding:NSUTF8StringEncoding];
  filename = @"niceFile.xml";
  self.sut = [MSErrorAttachmentLog attachmentWithBinary:data filename:filename];
  MSErrorAttachmentLog *other2 = [MSErrorAttachmentLog
      attachmentWithBinary:[@"<file><request>Please attach me</request><reason>I am a nice data.</reason></file>"
                                   dataUsingEncoding:NSUTF8StringEncoding]
                      filename:@"niceFile.xml"];
  other2.attachmentId = self.sut.attachmentId;

  // Then
  assertThat(self.sut, is(other2));
  assertThat(other1, isNot(other2));

  // When
  NSURL *whateverOtherObject = [NSURL new];

  // Then
  assertThat(self.sut, isNot(whateverOtherObject));
}

- (void)testIsValid {

  // If
  NSString *text = @"Please attach me, I am a nice text.";
  NSString *filename = @"niceFile.txt";
  
  // When
  self.sut = [MSErrorAttachmentLog attachmentWithText:text filename:filename];
  [self setDummyParentProperties:self.sut];
  self.sut.errorId = MS_UUID_STRING;
  BOOL validity = [self.sut isValid];

  // Then
  assertThatBool(validity, isTrue());

  // When
  self.sut = [MSErrorAttachmentLog attachmentWithText:[text copy] filename:[filename copy]];
  [self setDummyParentProperties:self.sut];
  self.sut.errorId = MS_UUID_STRING;
  self.sut.attachmentId = nil;
  validity = [self.sut isValid];

  // Then
  assertThatBool(validity, isFalse());

  // When
  self.sut = [MSErrorAttachmentLog attachmentWithText:[text copy] filename:[filename copy]];
  [self setDummyParentProperties:self.sut];
  self.sut.errorId = MS_UUID_STRING;
  self.sut.data = nil;
  validity = [self.sut isValid];

  // Then
  assertThatBool(validity, isFalse());
}

- (void)testSerialilzingToDictionary {

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"file_name"], equalTo(self.sut.filename));
  assertThat(actual[@"data"], equalTo([self.sut.data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn]));
}

- (void)testNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  MSErrorAttachmentLog *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([self.sut class]));
  assertThat(actual, equalTo(self.sut));
}

#pragma mark - Utility

- (void)setDummyParentProperties:(MSErrorAttachmentLog *)attachment {
  attachment.toffset = @(1);
  attachment.sid = MS_UUID_STRING;
  attachment.device = OCMClassMock([MSDevice class]);
  OCMStub([attachment.device isValid]).andReturn(YES);
}

@end
