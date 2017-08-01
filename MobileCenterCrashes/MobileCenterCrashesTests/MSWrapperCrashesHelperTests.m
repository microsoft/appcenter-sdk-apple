#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSCrashHandlerSetupDelegate.h"
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
