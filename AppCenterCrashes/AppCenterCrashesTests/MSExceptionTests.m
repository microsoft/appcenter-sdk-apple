#import "MSCrashesTestUtil.h"
#import "MSException.h"
#import "MSStackFrame.h"
#import "MSTestFrameworks.h"

@interface MSExceptionsTests : XCTestCase

@end

@implementation MSExceptionsTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {

  // If
  MSException *sut = [MSCrashesTestUtil exception];
  sut.innerExceptions = @[ [MSCrashesTestUtil exception] ];

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(sut.type));
  assertThat(actual[@"message"], equalTo(sut.message));
  assertThat(actual[@"stackTrace"], equalTo(sut.stackTrace));
  assertThat(actual[@"wrapperSdkName"], equalTo(sut.wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSException *sut = [MSCrashesTestUtil exception];
  sut.innerExceptions = @[ [MSCrashesTestUtil exception] ];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSException class]));

  MSException *actualException = actual;

  assertThat(actualException, equalTo(sut));
  assertThat(actualException.type, equalTo(sut.type));
  assertThat(actualException.message, equalTo(sut.message));
  assertThat(actualException.stackTrace, equalTo(sut.stackTrace));
  assertThat(actualException.wrapperSdkName, equalTo(sut.wrapperSdkName));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
  assertThat(actualException.frames.firstObject.address, equalTo(@"frameAddress"));
  assertThat(actualException.frames.firstObject.code, equalTo(@"frameSymbol"));
}

@end
