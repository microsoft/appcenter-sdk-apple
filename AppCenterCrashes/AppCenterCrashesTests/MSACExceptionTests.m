// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACCrashes.h"
#import "MSACException.h"
#import "MSACTestFrameworks.h"
#import <Foundation/Foundation.h>

@interface MSACExceptionsTests : XCTestCase

@end

@implementation MSACExceptionsTests

- (void)testInitWithException {

  // If.
  NSException *exception = [NSException exceptionWithName:@"Custom Exception"
                                                   reason:@"Custom Reason"
                                                 userInfo:@{@"Localized key" : @"Unexpected Input"}];

  // When.
  MSACException *msacException = [[MSACException alloc] initWithException:exception];

  // Then.
  XCTAssertEqualObjects(msacException.type, exception.name);
  XCTAssertEqualObjects(msacException.message, exception.reason);
  XCTAssertEqualObjects(msacException.stackTrace, exception.callStackSymbols.description);
}

- (void)testInitWithExceptionWhenAppPropertiesAreEmpty {

  // If.
  NSException *exception = [NSException new];

  // When.
  MSACException *msacException = [[MSACException alloc] initWithException:exception];

  // Then.
  XCTAssertNil(msacException.type);
  XCTAssertNil(msacException.message);
  XCTAssertNil(msacException.stackTrace);
}

- (void)testInitWithTypeAndMessage {

  // If.
  NSString *exceptionType = @"exception type";
  NSString *exceptionMessage = @"exception message";
  NSString *exceptionStackTrace = @"some stacktrace";

  // When.
  MSACException *msacException = [[MSACException alloc] initWithTypeAndMessage:@"exception type" exceptionMessage:@"exception message"];
  msacException.stackTrace = @"some stacktrace";

  // Then.
  XCTAssertEqualObjects(msacException.type, exceptionType);
  XCTAssertEqualObjects(msacException.message, exceptionMessage);
  XCTAssertEqualObjects(msacException.stackTrace, exceptionStackTrace);
}

- (void)testConvertNSErrorToMSACException {

  // If.
  NSString *domain = @"Some domain";
  NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{@"key" : @"value", @"key2" : @"value2"};
  NSError *error = [[NSError alloc] initWithDomain:domain code:0 userInfo:userInfo];

  // When.
  MSACException *msacException = [MSACException convertNSErrorToMSACException:error];

  // Then.
  XCTAssertEqualObjects(msacException.type, error.domain);
  XCTAssertEqualObjects(msacException.message, error.userInfo.description);
  XCTAssertNotNil(msacException.stackTrace);
}

- (void)testConvertNSErrorToMSACExceptionWhenUserInfoEmpty {

  // If.
  NSString *domain = @"Some domain";
  NSError *error = [[NSError alloc] initWithDomain:domain code:0 userInfo:nil];

  // When.
  MSACException *msacException = [MSACException convertNSErrorToMSACException:error];

  // Then.
  XCTAssertEqualObjects(msacException.type, error.domain);
  XCTAssertNil(msacException.message);
  XCTAssertNotNil(msacException.stackTrace);
}

- (void)testConvertNSErrorToMSACExceptionWhenAllPropertiesAreEmpty {

  // If.
  NSError *error = [NSError new];

  // When.
  MSACException *msacException = [MSACException convertNSErrorToMSACException:error];

  // Then.
  XCTAssertNil(msacException.type);
  XCTAssertNil(msacException.message);
  XCTAssertNotNil(msacException.stackTrace);
}

- (void)testSerializingBinaryToDictionary {

  // If.
  MSACException *msacException = [[MSACException alloc] initWithTypeAndMessage:@"exception type" exceptionMessage:@"exception message"];
  msacException.stackTrace = @"some stacktrace";
  NSMutableDictionary *actual = [msacException serializeToDictionary];

  // Then.
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(msacException.type));
  assertThat(actual[@"message"], equalTo(msacException.message));
  assertThat(actual[@"stackTrace"], equalTo(msacException.stackTrace));
}

- (void)testNSCodingSerializationAndDeserialization {

  // If.
  MSACException *msacException = [[MSACException alloc] initWithTypeAndMessage:@"exception type" exceptionMessage:@"exception message"];
  msacException.stackTrace = @"some stacktrace";

  // When.
  NSData *serializedEvent = [MSACUtility archiveKeyedData:msacException];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then.
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACException class]));
  MSACException *actualException = actual;

  // Verify exception's properties.
  assertThat(actualException, equalTo(msacException));
  assertThat(actualException.type, equalTo(msacException.type));
  assertThat(actualException.message, equalTo(msacException.message));
  assertThat(actualException.stackTrace, equalTo(msacException.stackTrace));
}

@end
