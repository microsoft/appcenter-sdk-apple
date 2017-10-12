#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"
#import "MSCrashesInternal.h"


@interface MSWrapperCrashesHelperTests : XCTestCase
@end

@implementation MSWrapperCrashesHelperTests

- (void)testSettingAndGettingDelegateWorks {
  
  // If
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  
  // When
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  
  // Then
  assertThat(delegateMock, equalTo(retrievedDelegate));
}

- (void)testSetAutomaticProcessing {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  
  // When
  [MSWrapperCrashesHelper setAutomaticProcessing:YES];
  
  // Then
  OCMVerify([crashesMock setAutomaticProcessing:YES]);
  
  // When
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  
  // Then
  OCMVerify([crashesMock setAutomaticProcessing:NO]);
}

- (void)testGetUnprocessedCrashReports {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *unprocessedReports = @[];
  OCMStub([crashesMock unprocessedCrashReports]).andReturn(unprocessedReports);
  
  // When
  NSArray *retrievedReports = [MSWrapperCrashesHelper unprocessedCrashReports];
  
  // Then
  OCMVerify([crashesMock unprocessedCrashReports]);
  XCTAssertEqual(unprocessedReports, retrievedReports);
}

- (void)testSendCrashReportsOrAwaitUserConfirmationForFilteredList {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *filteredIds = @[];
  
  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredIds:filteredIds];
  
  // Then
  OCMVerify([crashesMock sendCrashReportsOrAwaitUserConfirmationForFilteredIds:filteredIds]);
}

- (void)testsendErrorAttachmentsWithIncidentIdentifier {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *errorAttachments = @[];
  NSString *incidentId = @"incident id";
  
  // When
  [MSWrapperCrashesHelper sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentId];
  
  // Then
  OCMVerify([crashesMock sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentId]);
}

#pragma mark Helpers

- (MSCrashes*)getSharedCrashesMock {
  MSCrashes *crashesMock = OCMPartialMock([MSCrashes new]);
  id crashesClassMock = OCMClassMock([MSCrashes class]);
  OCMStub(ClassMethod([crashesClassMock sharedInstance])).andReturn(crashesMock);
  return crashesMock;
}

@end
