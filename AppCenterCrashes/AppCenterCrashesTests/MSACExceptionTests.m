// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACCrashes.h"
#import "MSACExceptionModel.h"
#import "MSACStackFrame.h"
#import "MSACTestFrameworks.h"
#import <Foundation/Foundation.h>
#import "MSACCrashesArchiverUtil.h"

@interface MSACExceptionsTests : XCTestCase

@end

@implementation MSACExceptionsTests

- (void)setUp {
  [super setUp];
  [MSACCrashesArchiverUtil addAllowedCrashesModuleClasses];
}

- (void)testInitWithException {

  // If.
  NSException *exception = [NSException exceptionWithName:@"Custom Exception"
                                                   reason:@"Custom Reason"
                                                 userInfo:@{@"Localized key" : @"Unexpected Input"}];

  // When.
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithException:exception];

  // Then.
  XCTAssertEqualObjects(msacException.type, exception.name);
  XCTAssertEqualObjects(msacException.message, exception.reason);
  XCTAssertNil(msacException.stackTrace);
  XCTAssertEqual(msacException.frames.count, 0);
}

- (void)testInitWithExceptionWhenAppPropertiesAreEmpty {

  // If.
  NSException *exception = [NSException new];

  // When.
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithException:exception];

  // Then.
  XCTAssertNil(msacException.type);
  XCTAssertNil(msacException.message);
  XCTAssertNil(msacException.stackTrace);
  XCTAssertNotNil(msacException.frames);
}

- (void)testInitWithType {

  // If.
  NSString *exceptionType = @"exception type";
  NSString *exceptionMessage = @"exception message";
  NSString *exceptionStackTrace =
      @"2   AppCenterCrashes                    0x0000000111986513 -[MSACCrashesTests testTrackErrorsWithPropertiesAndAttachments] + 4627";

  MSACStackFrame *excpectedFrame = [MSACStackFrame new];
  excpectedFrame.fileName = @"AppCenterCrashes";
  excpectedFrame.address = @"0x0000000111986513";
  excpectedFrame.className = @"MSACCrashesTests";
  excpectedFrame.methodName = @"testTrackErrorsWithPropertiesAndAttachments";

  // When.
  MSACExceptionModel *msacException =
      [[MSACExceptionModel alloc] initWithType:@"exception type"
                              exceptionMessage:@"exception message"
                                    stackTrace:[[NSArray<NSString *> alloc] initWithObjects:exceptionStackTrace, nil]];

  // Then.
  XCTAssertEqualObjects(msacException.type, exceptionType);
  XCTAssertEqualObjects(msacException.message, exceptionMessage);
  XCTAssertEqualObjects(msacException.frames.firstObject.address, excpectedFrame.address);
  XCTAssertEqualObjects(msacException.frames.firstObject.className, excpectedFrame.className);
  XCTAssertEqualObjects(msacException.frames.firstObject.fileName, excpectedFrame.fileName);
  XCTAssertEqualObjects(msacException.frames.firstObject.methodName, excpectedFrame.methodName);
}

- (void)testInitWithTypeWhenStackTraceWrong {

  // If.
  NSString *exceptionType = @"exception type";
  NSString *exceptionMessage = @"exception message";
  NSString *exceptionStackTrace =
      @"AppCenterCrashes                    0x0000000111986513 -[MSACCrashesTests testTrackErrorsWithPropertiesAndAttachments]";

  MSACStackFrame *excpectedFrame = [MSACStackFrame new];
  excpectedFrame.fileName = @"AppCenterCrashes";
  excpectedFrame.address = @"0x0000000111986513";
  excpectedFrame.className = @"MSACCrashesTests";
  excpectedFrame.methodName = @"testTrackErrorsWithPropertiesAndAttachments";

  // When.
  MSACExceptionModel *msacException =
      [[MSACExceptionModel alloc] initWithType:@"exception type"
                              exceptionMessage:@"exception message"
                                    stackTrace:[[NSArray<NSString *> alloc] initWithObjects:exceptionStackTrace, nil]];

  // Then.
  XCTAssertEqualObjects(msacException.type, exceptionType);
  XCTAssertEqualObjects(msacException.message, exceptionMessage);
  XCTAssertTrue([msacException.stackTrace containsString:exceptionStackTrace]);
  XCTAssertEqual(msacException.frames.count, 0);
}

- (void)testConvertNSErrorToMSACException {

  // If.
  NSString *domain = @"Some domain";
  NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{@"key" : @"value", @"key2" : @"value2"};
  NSError *error = [[NSError alloc] initWithDomain:domain code:0 userInfo:userInfo];

  // When.
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithError:error];

  // Then.
  XCTAssertEqualObjects(msacException.type, error.domain);
  XCTAssertEqualObjects(msacException.message, error.userInfo.description);
  XCTAssertNotNil(msacException.stackTrace);
  XCTAssertNotNil(msacException.frames);
}

- (void)testConvertNSErrorToMSACExceptionWhenUserInfoEmpty {

  // If.
  NSString *domain = @"Some domain";
  NSError *error = [[NSError alloc] initWithDomain:domain code:0 userInfo:nil];

  // When.
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithError:error];

  // Then.
  XCTAssertEqualObjects(msacException.type, error.domain);
  XCTAssertNil(msacException.message);
  XCTAssertNotNil(msacException.stackTrace);
  XCTAssertNotNil(msacException.frames);
}

- (void)testConvertNSErrorToMSACExceptionWhenAllPropertiesAreEmpty {

  // If.
  NSError *error = [NSError new];

  // When.
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithError:error];

  // Then.
  XCTAssertNil(msacException.type);
  XCTAssertNil(msacException.message);
  XCTAssertNotNil(msacException.stackTrace);
}

- (void)testSerializingBinaryToDictionary {

  // If.
  NSArray<NSString *> *stackTrace =
      [[NSArray alloc] initWithObjects:@"2   AppCenterCrashes                    0x0000000111986513 -[MSACCrashesTests "
                                       @"testTrackErrorsWithPropertiesAndAttachments] + 4627",
                                       nil];
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithType:@"exception type"
                                                              exceptionMessage:@"exception message"
                                                                    stackTrace:stackTrace];
  NSMutableDictionary *actual = [msacException serializeToDictionary];

  // Then.
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(msacException.type));
  assertThat(actual[@"message"], equalTo(msacException.message));
  assertThat(actual[@"stackTrace"], equalTo(msacException.stackTrace));
  NSDictionary *frames = actual[@"frames"][0];
  XCTAssertTrue([[frames objectForKey:@"address"] containsString:msacException.frames.firstObject.address]);
  XCTAssertTrue([[frames objectForKey:@"fileName"] containsString:msacException.frames.firstObject.fileName]);
  XCTAssertTrue([[frames objectForKey:@"className"] containsString:msacException.frames.firstObject.className]);
  XCTAssertTrue([[frames objectForKey:@"methodName"] containsString:msacException.frames.firstObject.methodName]);
}

- (void)testNSCodingSerializationAndDeserialization {

  // If.
  NSArray<NSString *> *stackTrace =
      [[NSArray alloc] initWithObjects:@"2   AppCenterCrashes                    0x0000000111986513 -[MSACCrashesTests "
                                       @"testTrackErrorsWithPropertiesAndAttachments] + 4627",
                                       nil];
  MSACExceptionModel *msacException = [[MSACExceptionModel alloc] initWithType:@"exception type"
                                                              exceptionMessage:@"exception message"
                                                                    stackTrace:stackTrace];

  // When.
  NSData *serializedEvent = [MSACUtility archiveKeyedData:msacException];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then.
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACExceptionModel class]));
  MSACExceptionModel *actualException = actual;

  // Verify exception's properties.
  assertThat(actualException, equalTo(msacException));
  assertThat(actualException.type, equalTo(msacException.type));
  assertThat(actualException.message, equalTo(msacException.message));
  assertThat(actualException.stackTrace, equalTo(msacException.stackTrace));
  assertThat(actualException.frames, equalTo(msacException.frames));
}

@end
