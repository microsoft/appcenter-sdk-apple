// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACCrashesArchiverUtil.h"
#import "MSACCrashesTestUtil.h"
#import "MSACStackFrame.h"
#import "MSACTestFrameworks.h"
#import "MSACWrapperExceptionModel.h"

@interface MSACExceptionsInternalTests : XCTestCase

@end

@implementation MSACExceptionsInternalTests

- (void)setUp {
  [super setUp];
  [MSACCrashesArchiverUtil addAllowedCrashesModuleClasses];
}

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {

  // If
  MSACWrapperExceptionModel *sut = [MSACCrashesTestUtil exception];
  sut.innerExceptions = @[ [MSACCrashesTestUtil exception] ];

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
  MSACWrapperExceptionModel *sut = [MSACCrashesTestUtil exception];
  sut.innerExceptions = @[ [MSACCrashesTestUtil exception] ];

  // When
  NSData *serializedEvent = [MSACUtility archiveKeyedData:sut];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACWrapperExceptionModel class]));

  MSACWrapperExceptionModel *actualException = actual;

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
