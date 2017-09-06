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

@end
