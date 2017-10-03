#import "MSCrashes.h"
#import "MSCrashesUtil.h"
#import "MSErrorReport.h"
#import "MSException.h"
#import "MSTestFrameworks.h"
#import "MSLogManagerDefault.h"
#import "MSChannelDefault.h"
#import "MSUtility+File.h"
#import "MSWrapperException.h"
#import "MSWrapperExceptionManagerInternal.h"
#import "MSCrashesTestUtil.h"
#import "MSErrorAttachmentLog.h"

// Copied from MSWrapperExceptionManager.m
static NSString* const kMSLastWrapperExceptionFileName = @"last_saved_wrapper_exception";
static NSString* const kMSTestAppSecret = @"app secret";

@interface MSWrapperExceptionManagerTests : XCTestCase

@property(nonatomic) MSCrashes *crashInstance;

@end

// Expose private methods for use in tests
@interface MSWrapperExceptionManager ()

+ (MSWrapperException *)loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename;

@end


@implementation MSWrapperExceptionManagerTests

#pragma mark - Housekeeping


-(void)tearDown {
  [super tearDown];
  [MSWrapperExceptionManager deleteAllWrapperExceptions];
}

#pragma mark - Helper

- (MSException*)getModelException {
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData*)getData {
  return [@"some string" dataUsingEncoding:NSUTF8StringEncoding];
}

- (MSWrapperException*)getWrapperException {
  MSWrapperException *wrapperException = [[MSWrapperException alloc] init];
  wrapperException.modelException = [self getModelException];
  wrapperException.exceptionData = [self getData];
  wrapperException.processId = [NSNumber numberWithInteger:rand()];
  return wrapperException;
}

- (void)assertWrapperException:(MSWrapperException*)wrapperException isEqualToOther:(MSWrapperException*)other {

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

- (void) testSaveCorrelateWrapperExceptionWhenExists {

  // If
  int numReports = 4;
  NSMutableArray *mockReports = [NSMutableArray new];
  for (int i = 0; i < numReports; ++i) {
    id reportMock = OCMPartialMock([MSErrorReport new]);
    OCMStub([reportMock appProcessIdentifier]).andReturn(i);
    OCMStub([reportMock incidentIdentifier]).andReturn([[NSUUID UUID] UUIDString]);
    [mockReports addObject:reportMock];
  }
  MSErrorReport *report = [mockReports objectAtIndex:(rand() % numReports)];
  MSWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = [NSNumber numberWithInteger:[report appProcessIdentifier]];

  // When
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithUUIDString:[report incidentIdentifier]];

  // Then
  XCTAssertNotNil(loadedException);
  [self assertWrapperException:wrapperException isEqualToOther:loadedException];
}

- (void) testSaveCorrelateWrapperExceptionWhenNotExists {

  // If
  MSWrapperException *wrapperException = [self getWrapperException];
  wrapperException.processId = [NSNumber numberWithInteger:4];
  NSMutableArray *mockReports = [NSMutableArray new];
  id reportMock = OCMPartialMock([MSErrorReport new]);
  OCMStub([reportMock appProcessIdentifier]).andReturn(9);
  NSString* uuidString = [[NSUUID UUID] UUIDString];
  OCMStub([reportMock incidentIdentifier]).andReturn(uuidString);
  [mockReports addObject:reportMock];

  // When
  [MSWrapperExceptionManager saveWrapperException:wrapperException];
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:mockReports];
  MSWrapperException *loadedException = [MSWrapperExceptionManager loadWrapperExceptionWithUUIDString:uuidString];

  // Then
  XCTAssertNil(loadedException);
}

- (void)testSendOrAwaitWhenAlwaysSendIsTrue {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:true];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperExceptionManager sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyAlwaysSend {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperExceptionManager sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual([reports count], 0);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifySend {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperExceptionManager sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual(0, numInvocations);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyDontSend {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperExceptionManager sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];

  // Then
  XCTAssertEqual(0, numInvocations);
}

- (void)testGetUnprocessedCrashReportsWhenThereAreNone {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  [self startCrashesWithReports:NO];

  // When
  NSArray<MSErrorReport *> *reports = [MSWrapperExceptionManager getUnprocessedCrashReports];

  // Then
  XCTAssertNil(reports);
}

- (void)testSendErrorAttachments {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  MSErrorReport *report = OCMPartialMock([MSErrorReport new]);
  NSUInteger numInvocations = 0;
  NSMutableArray<MSErrorAttachmentLog *> *attachments = [[NSMutableArray alloc] init];
  NSMutableArray<MSErrorAttachmentLog *> *foundAttachments = [[NSMutableArray alloc] init];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
    MSErrorAttachmentLog log = nil;
    [invocation getArgument:&log atIndex:2];

    // Ensure that the log corresponds to exactly one of the logs in the list that was passed
    XCTAssertFalse([foundAttachments containsObject:log]);
    [foundAttachments addObject:log];
    XCTAssertTrue([attachments containsObject:log]);
  })];
  NSArray<MSErrorReport *> *reports = [self startCrashesWithReports:NO];

  // When
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [MSWrapperExceptionManager sendErrorAttachments:attachments forErrorReport:report];

  // Then
  XCTAssertEqual([attachments count], numInvocations);
}

- (void)testGetUnprocessedCrashReports {

  // If
  [MSWrapperExceptionManager setAutomaticProcessing:false];
  int numReports = 3;
  NSArray<MSErrorReport *> *reports = [self startCrashesWithReportCount:numReports];

  // When
  NSArray<MSErrorReport *> *retrievedReports = [MSWrapperExceptionManager getUnprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], [retrievedReports count]);
  for (auto report in retrievedReports) {
    XCAssertTrue([reports containsObject:report]);
  }
}

- (NSArray<MSErrorReport *> *)startCrashesWithReports:(BOOL)startWithReports {
  if (startWithReports) {
    assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
    assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_signal"], isTrue());
    assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_empty"], isTrue());
    assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_xamarin"], isTrue());
    assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception_marketing"], isTrue());
  }

  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
}

// TODO: refactor these into utility if they can also be used by MSCrashesTests.
- (void)setAlwaysSendWithValue:(BOOL)value {
  [MS_USER_DEFAULTS setObject:[NSNumber numberWithBool:value] forKey:@"MSUserConfirmation"];
}

- (void)setEnqueueImplementation:(void (^)(NSInvocation *))invocation {
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  NSString *groupId = [[MSCrashes sharedInstance] groupId];
  NSMutableDictionary *channelsInLogManager =
  (static_cast<MSLogManagerDefault *>([MSCrashes sharedInstance].logManager)).channels;
  MSChannelDefault *channelMock = channelsInLogManager[groupId] = OCMPartialMock(channelsInLogManager[groupId]);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY withCompletion:OCMOCK_ANY]).andDo(invocation);
  [MSCrashes setDelegate:delegateMock];
}

@end
