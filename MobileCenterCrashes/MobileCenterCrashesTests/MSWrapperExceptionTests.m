#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "MSWrapperExceptionInternal.h"
#import "MSException.h"

@interface MSWrapperExceptionTests : XCTestCase

@property(nonatomic) MSWrapperException *sut;

@end

@implementation MSWrapperExceptionTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];

  self.sut = [self wrapperException];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Helper

- (MSWrapperException *)wrapperException {

  MSWrapperException *exception = [MSWrapperException new];
  exception.processId = [NSNumber numberWithInteger:4];
  exception.exceptionData = [[NSData alloc] initWithBase64EncodedString:@"data string" options:NSDataBase64DecodingIgnoreUnknownCharacters];
  exception.modelException = [[MSException alloc] init];
  exception.modelException.type = @"type";
  exception.modelException.message = @"message";
  exception.modelException.wrapperSdkName @"wrapper sdk name";

  return exception;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDictionaryWorks {
  NSDictionary *actual = [self.sut serializeToDictionary];
  XCTAssertNotNil(actual);
  assertThat(actual[@"process_id"], equalTo(self.sut.processId));
  assertThat(actual[@"exception_data"], equalTo(self.sut.exceptionData));
  assertThat(actual[@"model_exception"], equalTo(self.sut.modelException));

  // Exception fields.
  NSDictionary *exceptionDictionary = actual[@"model_exception"];
  XCTAssertNotNil(exceptionDictionary);
  assertThat(exceptionDictionary[@"type"], equalTo(self.sut.modelException.type));
  assertThat(exceptionDictionary[@"message"], equalTo(self.sut.modelException.message));
  assertThat(exceptionDictionary[@"wrapper_sdk_name"], equalTo(self.sut.modelException.wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // When
  NSData *serializedWrapperException = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedWrapperException];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSWrapperException class]));

  // The MSAppleErrorLog.
  MSWrapperException *actualWrapperException = actual;
  assertThat(actualWrapperException.processId, equalTo(self.sut.processId));
  assertThat(actualWrapperException.exceptionData, equalTo(self.sut.exceptionData));
  assertThat(actualWrapperException.modelException, equalTo(self.sut.modelException));

  // The exception field.
  MSException *actualException = actualWrapperException.modelException;
  assertThat(actualWrapperException.modelException.type, equalTo(self.sut.modelException.type));
  assertThat(actualWrapperException.modelException.message, equalTo(self.sut.modelException.message));
  assertThat(actualWrapperException.modelException.wrapperSdkName, equalTo(self.sut.modelException.wrapperSdkName));
}

@end
