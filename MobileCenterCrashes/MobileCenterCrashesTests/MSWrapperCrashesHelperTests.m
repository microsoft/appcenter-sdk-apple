#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"

@interface MSWrapperCrashesHelperTests : XCTestCase
@end

@implementation MSWrapperCrashesHelperTests

#pragma mark - Test

- (void)testSettingAndGettingDelegateWorks {
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  assertThat(delegateMock, equalTo(retrievedDelegate));
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
