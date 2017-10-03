#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"
#import "MSCrashesTestUtil.h"
#import "MSErrorAttachmentLog.h"
#import "MSChannelDefault.h"
#import "MSLogManagerDefault.h"
#import "MSCrashesInternal.h"
#import "MSCrashesDelegate.h"
#import "MSUtility.h"
#import "MSUserDefaults.h"
#import "MSErrorLogFormatter.h"
#import "MSCrashReporter.h"

@interface MSWrapperCrashesHelperTests : XCTestCase
@end

@implementation MSWrapperCrashesHelperTests

static NSString* const kMSTestAppSecret = @"app secret";

#pragma mark - Test

- (void)testSettingAndGettingDelegateWorks {
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  assertThat(delegateMock, equalTo(retrievedDelegate));
}

- (void)testSendOrAwaitWhenAlwaysSendIsTrue {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:true];
  __block NSUInteger numInvocations = 0;
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyAlwaysSend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  __block NSUInteger numInvocations = 0;
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual(numInvocations, (NSUInteger)0);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifySend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  __block NSUInteger numInvocations = 0;
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual((NSUInteger)0, numInvocations);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyDontSend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self setAlwaysSendWithValue:false];
  __block NSUInteger numInvocations = 0;
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
  })];
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];
  [reports removeObjectAtIndex:0];
  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];

  // Then
  XCTAssertEqual((NSUInteger)0, numInvocations);
}

- (void)testGetUnprocessedCrashReportsWhenThereAreNone {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self startCrashesWithReports:NO];

  // When
  NSArray<MSErrorReport *> *reports = [MSWrapperCrashesHelper getUnprocessedCrashReports];

  // Then
  XCTAssertNil(reports);
}

- (void)testSendErrorAttachments {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  MSErrorReport *report = OCMPartialMock([MSErrorReport new]);
  __block NSUInteger numInvocations = 0;
  __block NSMutableArray<MSErrorAttachmentLog *> *foundAttachments = [[NSMutableArray alloc] init];
  NSMutableArray<MSErrorAttachmentLog *> *attachments = [[NSMutableArray alloc] init];
  [self setEnqueueImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
    MSErrorAttachmentLog *attachmentLog;
    [invocation getArgument:&attachmentLog atIndex:2];
    [foundAttachments addObject:attachmentLog];
  })];
  [self startCrashesWithReports:NO];

  // When
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [attachments addObject:OCMPartialMock([MSErrorAttachmentLog new])];
  [MSWrapperCrashesHelper sendErrorAttachments:attachments forErrorReport:report];

  // Then
  XCTAssertEqual([attachments count], numInvocations);
  for (MSErrorAttachmentLog *log : foundAttachments) {
    [attachments containsObject:log];
  }
}

- (void)testGetUnprocessedCrashReports {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  NSArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];

  // When
  NSArray<MSErrorReport *> *retrievedReports = [MSWrapperCrashesHelper getUnprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], [retrievedReports count]);
  for (MSErrorReport* report : retrievedReports) {
    XCTAssertTrue([reports containsObject:report]);
  }
}

- (NSMutableArray<MSErrorReport *> *)startCrashesWithReports:(BOOL)startWithReports {
  NSMutableArray<MSErrorReport *> *reports = [NSMutableArray<MSErrorReport*> new];

  if (startWithReports) {
    for (NSString* fileName : @[@"live_report_exception",
                                @"live_report_signal",
                                @"live_report_empty",
                                @"live_report_xamarin",
                                @"live_report_exception_marketing"]) {
      assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:fileName], isTrue());
      NSData *data = [MSCrashesTestUtil dataOfFixtureCrashReportWithFileName:fileName];
      NSError *error;
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:data error:&error];
      [reports addObject:[MSErrorLogFormatter errorReportFromCrashReport:report]];
    }
  }
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  return reports;
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
