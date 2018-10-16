#import "MSCrashes.h"
#import "MSException.h"
#import "MSTestFrameworks.h"
#import "MSWrapperException.h"
#import "MSWrapperExceptionManagerInternal.h"

// Copied from MSWrapperExceptionManager.m
static NSString *const kMSLastWrapperExceptionFileName = @"last_saved_wrapper_exception";

@interface MSWrapperExceptionManagerTests : XCTestCase
@end

// Expose private methods for use in tests
@interface MSWrapperExceptionManager ()

+ (MSWrapperException *)loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename;

@end

@implementation MSWrapperExceptionManagerTests

#pragma mark - Housekeeping

- (void)tearDown {
  [super tearDown];
  [MSWrapperExceptionManager deleteAllWrapperExceptions];
}

#pragma mark - Helper

- (MSException *)getModelException {
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData *)getData {
  return [@"some string" dataUsingEncoding:NSUTF8StringEncoding];
}

- (MSWrapperException *)getWrapperException {
  MSWrapperException *wrapperException = [[MSWrapperException alloc] init];
  wrapperException.modelException = [self getModelException];
  wrapperException.exceptionData = [self getData];
  wrapperException.processId = @(rand());
  return wrapperException;
}

- (void)assertWrapperException:(MSWrapperException *)wrapperException isEqualToOther:(MSWrapperException *)other {

  // Test that the exceptions are the same.
  assertThat(other.processId, equalTo(wrapperException.processId));
  assertThat(other.exceptionData, equalTo(wrapperException.exceptionData));
  assertThat(other.modelException, equalTo(wrapperException.modelException));

  // The exception field.
  assertThat(other.modelException.type, equalTo(wrapperException.modelException.type));
  assertThat(other.modelException.message, equalTo(wrapperException.modelException.message));
  assertThat(other.modelException.wrapperSdkName, equalTo(wrapperException.modelException.wrapperSdkName));
}

#pragma mark - Test

- (void)testSaveAndLoadWrapperExceptionWorks {

  // If
  MSWrapperException *wrapperException = [self getWrapperException];

  // When
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithBaseFilename:kMSLastWrapperExceptionFileName];

  // Then
  XCTAssertNotNil(loadedException);
  [self assertWrapperException:wrapperException isEqualToOther:loadedException];
}

- (void)testSaveCorrelateWrapperExceptionWhenExists {

  // If
  int numReports = 4;
  NSMutableArray *mockReports = [NSMutableArray new];
  for (int i = 0; i < numReports; ++i) {
    id reportMock = OCMPartialMock([MSErrorReport new]);
    OCMStub([reportMock appProcessIdentifier]).andReturn(i);
    OCMStub([reportMock incidentIdentifier]).andReturn([[NSUUID UUID] UUIDString]);
    [mockReports addObject:reportMock];
  }
  MSErrorReport *report = mockReports[(NSUInteger)(rand() % numReports)];
  MSWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = @([report appProcessIdentifier]);

  // When
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithUUIDString:[report incidentIdentifier]];

  // Then
  XCTAssertNotNil(loadedException);
  [self assertWrapperException:wrapperException isEqualToOther:loadedException];
}

- (void)testSaveCorrelateWrapperExceptionWhenNotExists {

  // If
  MSWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = @4;
  NSMutableArray *mockReports = [NSMutableArray new];
  id reportMock = OCMPartialMock([MSErrorReport new]);
  OCMStub([reportMock appProcessIdentifier]).andReturn(9);
  NSString *uuidString = [[NSUUID UUID] UUIDString];
  OCMStub([reportMock incidentIdentifier]).andReturn(uuidString);
  [mockReports addObject:reportMock];

  // When
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithUUIDString:uuidString];

  // Then
  XCTAssertNil(loadedException);
}

@end
