#import "MSException.h"
#import "MSTestFrameworks.h"
#import "MSWrapperExceptionInternal.h"

@interface MSWrapperExceptionTests : XCTestCase

@property(nonatomic) MSWrapperException *sut;

@end

@implementation MSWrapperExceptionTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [self wrapperException];
}

#pragma mark - Helper

- (MSWrapperException *)wrapperException {
  MSWrapperException *exception = [MSWrapperException new];
  exception.processId = @4;
  exception.exceptionData = [@"data string" dataUsingEncoding:NSUTF8StringEncoding];
  exception.modelException = [[MSException alloc] init];
  exception.modelException.type = @"type";
  exception.modelException.message = @"message";
  exception.modelException.wrapperSdkName = @"wrapper sdk name";
  return exception;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDictionaryWorks {
  NSDictionary *actual = [self.sut serializeToDictionary];
  XCTAssertNotNil(actual);
  assertThat(actual[@"processId"], equalTo(self.sut.processId));
  assertThat(actual[@"exceptionData"], equalTo(self.sut.exceptionData));

  // Exception fields.
  NSDictionary *exceptionDictionary = actual[@"modelException"];
  XCTAssertNotNil(exceptionDictionary);
  assertThat(exceptionDictionary[@"type"], equalTo(self.sut.modelException.type));
  assertThat(exceptionDictionary[@"message"], equalTo(self.sut.modelException.message));
  assertThat(exceptionDictionary[@"wrapperSdkName"], equalTo(self.sut.modelException.wrapperSdkName));
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

  // The exception field.
  assertThat(actualWrapperException.modelException.type, equalTo(self.sut.modelException.type));
  assertThat(actualWrapperException.modelException.message, equalTo(self.sut.modelException.message));
  assertThat(actualWrapperException.modelException.wrapperSdkName, equalTo(self.sut.modelException.wrapperSdkName));
}

@end
