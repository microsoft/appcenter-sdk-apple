#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSAppleErrorLog.h"
#import "MSCrashesTestHelper.h"
#import "MSException.h"

@interface MSAppleErrorLogTests : XCTestCase

@property(nonatomic, strong) MSAppleErrorLog *sut;


@end


@implementation MSAppleErrorLogTests


#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  
  self.sut = [self appleErrorLog];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Helper

- (MSAppleErrorLog *)appleErrorLog {
  
  MSAppleErrorLog *appleLog = [MSAppleErrorLog new];
  appleLog.type = @"iOS Error";
  appleLog.primaryArchitectureId = @1;
  appleLog.architectureVariantId = @123;
  appleLog.applicationPath = @"user/something/something/mypath";
  appleLog.osExceptionType = @"NSSuperOSException";
  appleLog.osExceptionCode = @"0x08aeee81";
  appleLog.osExceptionAddress = @"0x124342345";
  appleLog.exceptionType = @"NSExceptionType";
  appleLog.exceptionReason = @"Trying to access array[12]";
  appleLog.exception = [MSCrashesTestHelper exception];
  
  return appleLog;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDicationaryWorks {
  NSDictionary *actual = [self.sut serializeToDictionary];
  XCTAssertNotNil(actual);
  assertThat(actual[@"type"], equalTo(self.sut.type));
  assertThat(actual[@"primary_architecture_id"], equalTo(self.sut.primaryArchitectureId));
  assertThat(actual[@"architecture_variant_id"], equalTo(self.sut.architectureVariantId));
  assertThat(actual[@"application_path"], equalTo(self.sut.applicationPath));
  assertThat(actual[@"os_exception_type"], equalTo(self.sut.osExceptionType));
  assertThat(actual[@"os_exception_code"], equalTo(self.sut.osExceptionCode));
  assertThat(actual[@"os_exception_address"], equalTo(self.sut.osExceptionAddress));
  assertThat(actual[@"exception_type"], equalTo(self.sut.exceptionType));
  assertThat(actual[@"exception_reason"], equalTo(self.sut.exceptionReason));
  
  NSDictionary *exceptionDicationary = actual[@"exception"];
  XCTAssertNotNil(exceptionDicationary);
  assertThat(exceptionDicationary[@"type"], equalTo(self.sut.exception.type));
  assertThat(exceptionDicationary[@"message"], equalTo(self.sut.exception.message));
  assertThat(exceptionDicationary[@"wrapper_sdk_name"], equalTo(self.sut.exception.wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSAppleErrorLog class]));
  
  MSAppleErrorLog *actualLog = actual;
  
  assertThat(actualLog.type, equalTo(self.sut.type));
  assertThat(actualLog.primaryArchitectureId, equalTo(self.sut.primaryArchitectureId));
  assertThat(actualLog.architectureVariantId, equalTo(self.sut.architectureVariantId));
  assertThat(actualLog.applicationPath, equalTo(self.sut.applicationPath));
  assertThat(actualLog.osExceptionType, equalTo(self.sut.osExceptionType));
  assertThat(actualLog.osExceptionCode, equalTo(self.sut.osExceptionCode));
  assertThat(actualLog.osExceptionAddress, equalTo(self.sut.osExceptionAddress));
  assertThat(actualLog.exceptionType, equalTo(self.sut.exceptionType));
  assertThat(actualLog.exceptionReason, equalTo(self.sut.exceptionReason));
  
  MSException *actualException = actualLog.exception;
  
  assertThat(actualException.type, equalTo(self.sut.exception.type));
  assertThat(actualException.message, equalTo(self.sut.exception.message));
  assertThat(actualException.wrapperSdkName, equalTo(self.sut.exception.wrapperSdkName));
}

@end
