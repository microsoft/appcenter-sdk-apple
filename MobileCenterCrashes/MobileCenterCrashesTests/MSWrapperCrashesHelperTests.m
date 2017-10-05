#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"
#import "MSCrashesTestUtil.h"
#import "MSErrorAttachmentLog.h"
#import "MSChannelDefault.h"
#import "MSLogManagerDefault.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesDelegate.h"
#import "MSUtility.h"
#import "MSUserDefaults.h"
#import "MSErrorLogFormatter.h"
#import "MSCrashReporter.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

@interface MSWrapperCrashesHelperTests : XCTestCase
@end

@implementation MSWrapperCrashesHelperTests

- (void)testSettingAndGettingDelegateWorks {
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  assertThat(delegateMock, equalTo(retrievedDelegate));
}

@end
